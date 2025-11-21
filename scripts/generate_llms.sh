#!/usr/bin/env bash
set -euo pipefail

# llms.txt generator
# Usage:
#   ./scripts/generate_llms.sh --llm-all
#   ./scripts/generate_llms.sh --base <old> --head <new> [--llm]
#   ./scripts/generate_llms.sh --compare "<old>...<new>" [--llm]
# Env:
#   OPENAI_API_KEY  required for --llm
#   INCLUDE_DIRS    dirs to scan (default ".")
#   EXCLUDE_DIRS    pruned dirs (default: node_modules build dist .git .swiftpm .gradle .idea .next)
#   EXTENSIONS      file extensions (default: swift)
#   DEFAULT_BRANCH  override branch for raw links (auto-detected)
#   REPO_SLUG       org/repo (auto-detected)
#   REPO_URL        optional repo to clone/scan
#   OUTPUT          output path (default: llms.txt). Use OUTPUT="-" or --stdout for stdout
# Notes:
#   - Builds a flat index grouped by folder paths (no categories).
#   - Incremental mode updates only new/changed files when base/head (or compare) provided.
#   - Descriptions use full raw GitHub content for accurate context.

# Parse args: PLATFORM as first positional, optional REPO_URL, simple flags
PRINT_STDOUT="false"
USE_LLM="false"
LLM_FORCE_ALL="false"
OPENAI_BASE_URL="${OPENAI_BASE_URL:-https://api.openai.com}"
OPENAI_MODEL="${OPENAI_MODEL:-gpt-5-mini}"
LLM_SLEEP_SEC="${LLM_SLEEP_SEC:-0.25}"
LLM_SOURCE="${LLM_SOURCE:-raw}" # raw | local
LLM_LOG="${LLM_LOG:-true}"      # log LLM outputs to stderr when true
LLM_MAX_BYTES="${LLM_MAX_BYTES:-0}" # 0 = no limit; otherwise truncate to this many bytes
args=("$@")
positional=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      BASE_REF="${2:-}"
      shift 2
      ;;
    --head)
      HEAD_REF="${2:-}"
      shift 2
      ;;
    --compare)
      COMPARE_RANGE="${2:-}"
      shift 2
      ;;
    --stdout)
      PRINT_STDOUT="true"
      shift
      ;;
    --llm)
      USE_LLM="true"
      shift
      ;;
    --llm-all)
      USE_LLM="true"
      LLM_FORCE_ALL="true"
      shift
      ;;
    --output|-o)
      OUTPUT="${2:-}"
      shift 2
      ;;
    --branch)
      DEFAULT_BRANCH="${2:-}"
      shift 2
      ;;
    --slug)
      REPO_SLUG="${2:-}"
      shift 2
      ;;
    *)
      positional+=("$1")
      shift
      ;;
  esac
done
set -- "${positional[@]}"
REPO_URL="${REPO_URL:-${1:-}}"
if [[ "${OUTPUT:-}" == "-" ]]; then
  PRINT_STDOUT="true"
fi

DEFAULT_EXT="swift"

# Auto-detect INCLUDE_DIRS if not provided: prefer Sources, Samples, Tests, and root Package.swift (plus legacy Notifly sample names)
if [[ -z "${INCLUDE_DIRS:-}" ]]; then
  dirs=()
  [[ -d "Sources" ]] && dirs+=("Sources")
  [[ -d "Samples" ]] && dirs+=("Samples")
  [[ -d "Tests" ]] && dirs+=("Tests")
  [[ -f "Package.swift" ]] && dirs+=("Package.swift")
  [[ -f "README.md" ]] && dirs+=("README.md")
  [[ -d "NotiflyIOSSample" ]] && dirs+=("NotiflyIOSSample")
  [[ -d "NotiflyTestApp" ]] && dirs+=("NotiflyTestApp")
  if [[ ${#dirs[@]} -gt 0 ]]; then
    INCLUDE_DIRS="${dirs[*]}"
  else
    INCLUDE_DIRS="."
  fi
fi
EXCLUDE_DIRS="${EXCLUDE_DIRS:-node_modules build dist .git .swiftpm .gradle .idea .next .github .vscode .sourcekit-lsp}"
EXTENSIONS="${EXTENSIONS:-$DEFAULT_EXT}"

# If REPO_URL is provided, clone into a temp directory
ORIGINAL_PWD="$(pwd)"
TEMP_CLONE_DIR=""
if [[ -n "$REPO_URL" ]]; then
  TEMP_CLONE_DIR="$(mktemp -d)"
  echo "Cloning $REPO_URL ..." >&2
  git clone --depth 1 "$REPO_URL" "$TEMP_CLONE_DIR" >&2
  cd "$TEMP_CLONE_DIR"
fi

# Prefer GitHub Actions token automatically if present
GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

# Current HEAD commit (for diff detection and header)
HEAD_SHA="$(git rev-parse HEAD 2>/dev/null || echo "")"

# Resolve repo slug from git remote (or REPO_URL)
REPO_SLUG="${REPO_SLUG:-}"
if [[ -z "$REPO_SLUG" ]]; then
  remote="$(git config --get remote.origin.url || echo "$REPO_URL" || true)"
  if [[ "$remote" =~ ^git@github\.com:(.+)\.git$ ]]; then
    REPO_SLUG="${BASH_REMATCH[1]}"
  elif [[ "$remote" =~ ^https://github\.com/(.+)\.git$ ]]; then
    REPO_SLUG="${BASH_REMATCH[1]}"
  elif [[ "$remote" =~ ^https://github\.com/(.+)$ ]]; then
    REPO_SLUG="${BASH_REMATCH[1]}"
  else
    echo "Cannot parse REPO_SLUG from remote or REPO_URL; set REPO_SLUG=org/repo" >&2
    exit 1
  fi
fi

# Resolve branch (prefer remote default branch to avoid CI temp branches)
DEFAULT_BRANCH="${DEFAULT_BRANCH:-}"
if [[ -z "$DEFAULT_BRANCH" ]]; then
  if origin_head="$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null)"; then
    DEFAULT_BRANCH="${origin_head##*/}"
  else
    DEFAULT_BRANCH="$(git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}' | head -n1)"
    [[ -z "$DEFAULT_BRANCH" ]] && DEFAULT_BRANCH="main"
  fi
fi

RAW_BASE="https://raw.githubusercontent.com/${REPO_SLUG}/${DEFAULT_BRANCH}"
REPO_ROOT_RAW="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# Canonicalize repo root to physical path (avoid /var vs /private/var mismatch on macOS)
REPO_ROOT="$(cd "$REPO_ROOT_RAW" && pwd -P)"

# Human-readable platform for header (fixed: iOS)
human_platform="iOS"

# Determine output path
DEFAULT_OUTPUT="llms.txt"
if [[ "${PRINT_STDOUT}" == "true" ]]; then
  OUTPUT_PATH=""
else
  OUTPUT_PATH="${OUTPUT:-"$ORIGINAL_PWD/$DEFAULT_OUTPUT"}"
fi

# Init output
write_line() {
  if [[ -z "${OUTPUT_SINK:-}" ]]; then
    printf "%s\n" "$1"
  else
    printf "%s\n" "$1" >> "$OUTPUT_SINK"
  fi
}
# Note: Do NOT truncate OUTPUT_PATH yet; we must read the existing LLMS first.

# Helpers
require_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# URL builder and text-mode helpers
url_encode_spaces() { printf "%s" "$1" | sed 's/ /%20/g'; }
rel_to_url() { printf "%s/%s" "$RAW_BASE" "$(url_encode_spaces "$1")"; }

path_is_target() {
  local rel="$1"
  local base="$(basename "$rel")"
  # Whitelist select top-level docs regardless of EXTENSIONS/INCLUDE_DIRS
  case "$base" in
    README.md|CHANGELOG.md|LICENSE|Package.swift) return 0 ;;
  esac
  # Check extension
  local ext="${rel##*.}"
  local match_ext=0
  for e in "${exts[@]}"; do
    e="${e// /}"
    [[ -z "$e" ]] && continue
    if [[ "$ext" == "$e" ]]; then match_ext=1; break; fi
  done
  [[ $match_ext -eq 1 ]] || return 1
  # Check included dirs
  for d in $INCLUDE_DIRS; do
    case "$rel" in
      "$d"/*|"$d") return 0 ;;
    esac
  done
  # If INCLUDE_DIRS is ".", allow all
  if [[ "$INCLUDE_DIRS" == "." ]]; then return 0; fi
  return 1
}

replace_or_append_line() {
  local rel="$1" raw_url="$2" newline="$3" dir_rel="$4"
  if grep -F "](${raw_url}):" "$OUTFILE" >/dev/null 2>&1; then
    awk -v url="$raw_url" -v nl="$newline" 'index($0, "](" url "):") {print nl; next} {print}' "$OUTFILE" > "$OUTFILE.tmp" && mv "$OUTFILE.tmp" "$OUTFILE"
  else
    # Ensure section header exists
    if ! grep -xq "## ${dir_rel}" "$OUTFILE" >/dev/null 2>&1; then
      printf "\n## %s\n" "$dir_rel" >> "$OUTFILE"
    fi
    awk -v hdr="## ${dir_rel}" -v nl="$newline" 'ins==0 && $0==hdr {print; print nl; ins=1; next} {print}' "$OUTFILE" > "$OUTFILE.tmp" && mv "$OUTFILE.tmp" "$OUTFILE"
  fi
}

remove_line_by_url() {
  local raw_url="$1"
  awk -v url="$raw_url" 'index($0, "](" url "):")==0' "$OUTFILE" > "$OUTFILE.tmp" && mv "$OUTFILE.tmp" "$OUTFILE"
}

update_header_in_place() {
  local commit="$1" ts="$2"
  awk -v c="$commit" -v t="$ts" '
    NR==1{print; next}
    /^<!-- ref:/ {print; next}
    /^<!-- repo:/ {print; next}
    /^<!-- commit:/ {print "<!-- commit: " c " -->"; next}
    /^<!-- generated_at:/ {print "<!-- generated_at: " t " -->"; next}
    {print}
  ' "$OUTFILE" > "$OUTFILE.tmp" && mv "$OUTFILE.tmp" "$OUTFILE"
}
titleize() {
  local base="$1"
  base="${base%.*}"                # drop extension
  base="${base//[-_]/ }"           # replace - and _ with space
  # capitalize words using awk (portable)
  awk '{
    for (i=1;i<=NF;i++) {
      first=substr($i,1,1); rest=substr($i,2);
      printf "%s%s%s", toupper(first), tolower(rest), (i<NF ? " " : "")
    }
    printf "\n"
  }' <<<"$base"
}

first_comment_line() {
  # Extract first non-empty single-line comment as description (//, ///, or #)
  local file="$1"
  # shellcheck disable=SC2016
  sed -n -E '
    s/^[[:space:]]*\/\/\/?[[:space:]]*(.+)$/\1/p;
    s/^[[:space:]]*#[[:space:]]*(.+)$/\1/p;
  ' "$file" | sed -n '1p' || true
}

# Optional: LLM enrichment using OpenAI Responses API (cost-aware)
fetch_code_for_llm() {
  local url="$1" file="$2"
  local code=""
  if [[ "$LLM_SOURCE" == "raw" && -n "$url" ]]; then
    code="$(curl -Lsf "$url" 2>/dev/null | sed 's/```/`backticks`/g' || true)"
  fi
  if [[ -z "$code" && -n "$file" && -f "$file" ]]; then
    code="$(sed 's/```/`backticks`/g' "$file" || true)"
  fi
  # Optional truncate
  if [[ -n "$code" && "$LLM_MAX_BYTES" != "0" ]]; then
    code="$(printf "%s" "$code" | head -c "$LLM_MAX_BYTES")"
  fi
  printf "%s" "$code"
}

llm_describe_file() {
  local rel="$1" file="$2" url="$3" section="$4" repo="$5"
  if [[ "$USE_LLM" != "true" ]]; then
    return 0
  fi
  if ! require_cmd curl || ! require_cmd jq; then
    echo "LLM disabled: curl/jq missing" >&2
    return 0
  fi
  if [[ -z "${OPENAI_API_KEY:-}" ]]; then
    echo "LLM disabled: OPENAI_API_KEY not set" >&2
    return 0
  fi
  local ext="${file##*.}"
  local lang=""
  case "$ext" in
    swift) lang="swift" ;;
    kt) lang="kotlin" ;;
    dart) lang="dart" ;;
    ts|tsx) lang="typescript" ;;
    js|jsx) lang="javascript" ;;
    *) lang="" ;;
  esac
  local code
  code="$(fetch_code_for_llm "$url" "$file")"
  local input_prompt="You are a senior SDK engineer. Write 1 concise sentence (<= 40 words) describing this SDK source file for a developer-facing index. Be specific and technical (core responsibilities, key flows/side-effects, dependencies, notable public APIs/entry points).
Repository: ${repo}
Section: ${section}
Path: ${rel}

Source code (${lang}):

\`\`\`${lang}
${code}
\`\`\`"
  local payload
  payload="$(jq -n --arg model "$OPENAI_MODEL" --arg input "$input_prompt" '{model:$model, input:$input}')" || return 0
  local resp
  resp="$(curl -sS -X POST \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    -H "Content-Type: application/json" \
    --data "$payload" \
    "$OPENAI_BASE_URL/v1/responses")" || { echo "[LLM ERROR] HTTP request failed for $rel" >&2; return 0; }
  local out
  local err_msg
  err_msg="$(echo "$resp" | jq -r '.error.message // empty' 2>/dev/null || true)"
  out="$(echo "$resp" | jq -r '
    if (.output_text // "") != "" then .output_text
    else ([.output[]? | .content[]? | .text? // empty] | join("\n"))
    end
  ' 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | sed 's/[[:space:]]$//')"
  # POSIX-safe clamp to max 2 sentences and ~40 words
  out="$(printf '%s' "$out" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/ \././g')"
  first_two="$(printf '%s' "$out" | grep -oE '^([^.!?]*[.!?]){1,2}')"
  [ -z "$first_two" ] && first_two="$out"
  out="$(printf '%s' "$first_two" | awk '{n=0; for(i=1;i<=NF;i++){ if(n<40){ if(i>1) printf " "; printf "%s", $i; n++ } } if(NF>40) printf "..."; printf "\n"}')"
  if [[ -z "$out" && -n "$err_msg" ]]; then
    echo "[LLM ERROR] $rel -> $err_msg" >&2
  fi
  if [[ -z "$out" ]]; then
    # last resort: print raw (trimmed) for debugging
    echo "[LLM DEBUG] raw response for $rel: $(echo "$resp" | tr '\n' ' ' | head -c 400)" >&2
  fi
  if [[ "$LLM_LOG" == "true" ]]; then
    if [[ -n "$out" ]]; then
      echo "[LLM] $rel -> $out" >&2
    else
      echo "[LLM] $rel -> (empty response)" >&2
    fi
  fi
  printf "%s" "$out"
}

# Build -name predicates for find
IFS=',' read -r -a exts <<<"$EXTENSIONS"
name_pred=""
for ext in "${exts[@]}"; do
  ext="${ext// /}"
  if [[ -z "$ext" ]]; then continue; fi
  if [[ -z "$name_pred" ]]; then
    name_pred="-name '*.$ext'"
  else
    name_pred="$name_pred -o -name '*.$ext'"
  fi
done

# Build exclude predicate
exclude_pred=""
for d in $EXCLUDE_DIRS; do
  exclude_pred="$exclude_pred -path '*/$d' -prune -o"
done

 # Truncate output and write header AFTER reading existing LLMS map

# Temp workspace (no associative arrays in macOS Bash 3.2)
SECTION_TMP_DIR="$(mktemp -d)"
trap '[[ -d "$SECTION_TMP_DIR" ]] && rm -rf "$SECTION_TMP_DIR"' EXIT

# Existing LLMS map for incremental LLM usage: url \t desc
EXISTING_MAP="${SECTION_TMP_DIR}/existing_map.tsv"
> "$EXISTING_MAP"
EXISTING_LLMS_PATH="${EXISTING_LLMS:-"$ORIGINAL_PWD/$DEFAULT_OUTPUT"}"
if [[ -f "$EXISTING_LLMS_PATH" ]]; then
  # Extract url and desc using sed (portable on macOS/BSD)
  # Line format: - [Title](URL): Description
  while IFS= read -r line; do
    case "$line" in
      -*\[*\]\(*\)*)
        url="$(printf "%s\n" "$line" | sed -nE 's/.*\]\(([^)]*)\).*/\1/p')"
        desc="$(printf "%s\n" "$line" | sed -nE 's/^[[:space:]]*-[[:space:]]*\[[^]]+\]\([^)]*\):[[:space:]]*//p' | sed 's/[[:space:]]*<!--.*$//' | tr -d '\r')"
        if [[ -n "$url" ]]; then
          printf "%s\t%s\n" "$url" "$desc" >> "$EXISTING_MAP"
        fi
        ;;
    esac
  done < "$EXISTING_LLMS_PATH"
fi

# Folder-based grouping
DIR_LIST="${SECTION_TMP_DIR}/dirs.txt"
> "$DIR_LIST"
sanitize_dir() {
  # Replace slashes and spaces to form a safe filename
  printf "%s" "$1" | sed 's#[/ ]#_#g; s#[^A-Za-z0-9._-]#_#g'
}
append_to_dir() {
  local dir_rel="$1"; shift
  local line="$*"
  local key; key="$(sanitize_dir "$dir_rel")"
  local file="${SECTION_TMP_DIR}/dir_${key}.txt"
  printf "%s\n" "$line" >> "$file"
  printf "%s\n" "$dir_rel" >> "$DIR_LIST"
}

# Prepare a staging sink and write header there (atomic replacement later)
STAGING_PATH="${SECTION_TMP_DIR}/staging.txt"
if [[ -n "${OUTPUT_PATH}" ]]; then
  OUTPUT_SINK="$STAGING_PATH"
  : > "$OUTPUT_SINK"
else
  OUTPUT_SINK=""
fi
write_line "<!-- repo: ${REPO_SLUG} -->"
write_line "<!-- ref: ${DEFAULT_BRANCH} -->"

# Build changed files set from GitHub compare if provided
CHANGED_SET="${SECTION_TMP_DIR}/changed_paths.txt"
> "$CHANGED_SET"
if [[ -n "${COMPARE_RANGE:-}" ]]; then
  BASE_REF="${COMPARE_RANGE%%...*}"
  HEAD_REF="${COMPARE_RANGE##*...}"
fi
if [[ -n "${BASE_REF:-}" && -n "${HEAD_REF:-}" ]]; then
  echo "Fetching changed files: ${BASE_REF}...${HEAD_REF}" >&2
  # If a HEAD ref is provided, prefer its SHA for the header
  new_head_sha="$(git rev-parse "${HEAD_REF}" 2>/dev/null || true)"
  if [[ -n "$new_head_sha" ]]; then
    HEAD_SHA="$new_head_sha"
  fi
  if [[ -n "${GH_TOKEN:-}" ]]; then
    AUTH_HDR=( -H "Authorization: Bearer ${GH_TOKEN}" )
    compare_json="$(curl -sS -H "Accept: application/vnd.github+json" "${AUTH_HDR[@]}" \
      "https://api.github.com/repos/${REPO_SLUG}/compare/${BASE_REF}...${HEAD_REF}" || true)"
    printf "%s\n" "$compare_json" | jq -r '
      .files[]?
      | select(.status=="modified" or .status=="added" or .status=="renamed" or .status=="removed" or .status=="deleted")
      | (.filename, (.previous_filename // empty))
    ' 2>/dev/null | sed '/^$/d; s#^./##' | sort -u >> "$CHANGED_SET"
  else
    git fetch --no-tags --depth=1 origin "${BASE_REF}" "${HEAD_REF}" >/dev/null 2>&1 || true
    git diff --name-only "${BASE_REF}...${HEAD_REF}" 2>/dev/null | sed 's#^./##' | sort -u >> "$CHANGED_SET" || true
  fi
fi

# If we have an existing LLMS and a changed set, do TEXT-MODE update (surgical)
if [[ -f "$EXISTING_LLMS_PATH" && -s "$CHANGED_SET" ]]; then
  OUTFILE="$STAGING_PATH"
  cp "$EXISTING_LLMS_PATH" "$OUTFILE" 2>/dev/null || : > "$OUTFILE"
  while IFS= read -r rel || [[ -n "$rel" ]]; do
    [[ -z "$rel" ]] && continue
    # Only operate on target paths (INCLUDE_DIRS + EXTENSIONS)
    if ! path_is_target "$rel"; then
      continue
    fi
    abs_file="${REPO_ROOT}/${rel}"
    raw_url="$(rel_to_url "$rel")"
    dir_rel="$(dirname "$rel")"; dir_rel="${dir_rel:-.}"
    # If the line already exists and LLM is not requested, keep it verbatim
    if grep -F -q "](${raw_url}):" "$OUTFILE" >/dev/null 2>&1; then
      if [[ "$USE_LLM" != "true" ]]; then
        continue
      fi
    fi
    if [[ -f "$abs_file" ]]; then
      title="$(titleize "$(basename "$abs_file")")"
      # Default to existing description if present
      existing_line="$(awk -F '\t' -v u="$raw_url" '$1==u{print $0; exit}' "$EXISTING_MAP" 2>/dev/null || true)"
      desc="$(printf "%s" "$existing_line" | cut -f2- || true)"
      if [[ -z "$desc" ]]; then
        # Generate quickly (may call LLM if enabled)
        f_desc="$(first_comment_line "$abs_file" || true)"
        [[ -z "$f_desc" ]] && f_desc="Source file for ${title}"
        if [[ "$USE_LLM" == "true" ]]; then
          llm_desc="$(llm_describe_file "$rel" "$abs_file" "$raw_url" "$dir_rel" "$REPO_SLUG" || true)"
          [[ -n "$llm_desc" ]] && f_desc="$llm_desc"
        fi
        desc="$f_desc"
      fi
      newline="- [${title}](${raw_url}): ${desc}"
      replace_or_append_line "$rel" "$raw_url" "$newline" "$dir_rel"
    else
      # Removed file: delete line if present
      remove_line_by_url "$raw_url"
    fi
  done < "$CHANGED_SET"
  # Update header commit and timestamp
  update_header_in_place "$HEAD_SHA" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  # Finalize output
  if [[ -n "${OUTPUT_PATH}" && -n "${OUTPUT_SINK:-}" ]]; then
    mv "$OUTFILE" "$OUTPUT_PATH"
    echo "Wrote ${OUTPUT_PATH}" >&2
  else
    cat "$OUTFILE"
  fi
  exit 0
fi

# If a compare range was provided but there are NO changes, just refresh header and exit
if [[ -f "$EXISTING_LLMS_PATH" && -n "${COMPARE_RANGE:-${BASE_REF:-}${HEAD_REF:-}}" && ! -s "$CHANGED_SET" ]]; then
  OUTFILE="$STAGING_PATH"
  cp "$EXISTING_LLMS_PATH" "$OUTFILE" 2>/dev/null || : > "$OUTFILE"
  update_header_in_place "$HEAD_SHA" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ -n "${OUTPUT_PATH}" && -n "${OUTPUT_SINK:-}" ]]; then
    mv "$OUTFILE" "$OUTPUT_PATH"
    echo "Wrote ${OUTPUT_PATH}" >&2
  else
    cat "$OUTFILE"
  fi
  exit 0
fi

# Now that HEAD_SHA is finalized (and no surgical mode), write header
write_line "<!-- commit: ${HEAD_SHA} -->"
write_line "<!-- generated_at: $(date -u +%Y-%m-%dT%H:%M:%SZ) -->"
write_line "# Platform: ${human_platform}"

# No category mapping; grouping is by directory path

flush_file() {
  # $1 path
  if [[ -s "$1" ]]; then
    if [[ -z "${OUTPUT_SINK:-}" ]]; then
      cat "$1"
    else
      cat "$1" >> "$OUTPUT_SINK"
    fi
  fi
}

# Iterate include dirs and collect lines
for dir in $INCLUDE_DIRS; do
  # If an explicit file path is provided (e.g., Package.swift, README.md), handle it directly
  if [[ -f "$dir" ]]; then
    file="$dir"
    abs_file="$(cd "$(dirname "$file")" && pwd -P)/$(basename "$file")"
    rel="${abs_file#$REPO_ROOT/}"
    url_path="${rel// /%20}"
    raw_url="${RAW_BASE}/${url_path}"
    title="$(titleize "$(basename "$file")")"
    existing_line="$(awk -F '\t' -v u="$raw_url" '$1==u{print $0; exit}' "$EXISTING_MAP" 2>/dev/null || true)"
    existing_desc="$(printf "%s" "$existing_line" | cut -f2- || true)"
    desc="$(first_comment_line "$abs_file" || true)"
    [[ -z "$desc" ]] && desc="Source file for ${title}"
    if [[ -n "$existing_desc" ]]; then
      desc="$existing_desc"
    fi
    if [[ "$USE_LLM" == "true" ]]; then
      need_llm="false"
      if [[ -z "$existing_line" ]]; then
        need_llm="true"
      fi
      if [[ "$need_llm" == "true" ]]; then
        dir_label="$(dirname "$rel")"
        dir_label="${dir_label:-.}"
        llm_desc="$(llm_describe_file "$rel" "$abs_file" "$raw_url" "$dir_label" "$REPO_SLUG" || true)"
        if [[ -n "$llm_desc" ]]; then
          desc="$llm_desc"
          sleep "$LLM_SLEEP_SEC"
        fi
      fi
    fi
    line="- [${title}](${raw_url}): ${desc}"
    dir_rel="$(dirname "$rel")"
    dir_rel="${dir_rel:-.}"
    append_to_dir "$dir_rel" "$line"
    continue
  fi
  # Build the find command safely using an array (no eval, portable parens)
  find_args=( "$dir" )
  for d in $EXCLUDE_DIRS; do
    find_args+=( -path "*/$d" -prune -o )
  done
  find_args+=( \( )
  first_name=1
  for ext in "${exts[@]}"; do
    ext="${ext// /}"
    [[ -z "$ext" ]] && continue
    if [[ $first_name -eq 1 ]]; then
      find_args+=( -name "*.$ext" )
      first_name=0
    else
      find_args+=( -o -name "*.$ext" )
    fi
  done
  find_args+=( \) -type f -print0 )

  while IFS= read -r -d '' file; do
    # Compute absolute path and repo-relative path (portable)
    abs_file="$(cd "$(dirname "$file")" && pwd -P)/$(basename "$file")"
    rel="${abs_file#$REPO_ROOT/}"
    url_path="${rel// /%20}"
    raw_url="${RAW_BASE}/${url_path}"
    title="$(titleize "$(basename "$file")")"
    # Existing description from previous LLMS (if any)
    existing_line="$(awk -F '\t' -v u="$raw_url" '$1==u{print $0; exit}' "$EXISTING_MAP" 2>/dev/null || true)"
    existing_desc="$(printf "%s" "$existing_line" | cut -f2- || true)"
    # (no full-line cache; surgical updates are handled earlier)
    # Start with fallback description
    desc="$(first_comment_line "$abs_file" || true)"
    [[ -z "$desc" ]] && desc="Source file for ${title}"
    # Prefer existing description when available
    if [[ -n "$existing_desc" ]]; then
      desc="$existing_desc"
    fi
    # LLM enrichment with incremental policy
    if [[ "$USE_LLM" == "true" ]]; then
      need_llm="false"
      if [[ "$LLM_FORCE_ALL" == "true" ]]; then
        need_llm="true"
      elif [[ -s "$CHANGED_SET" ]]; then
        if grep -F -q "$rel" "$CHANGED_SET"; then
          need_llm="true"
        fi
      else
        # No compare range provided: only LLM for files not seen before
        if [[ -z "$existing_line" ]]; then
          need_llm="true"
        fi
      fi
      if [[ "$need_llm" == "true" ]]; then
        dir_label="$(dirname "$rel")"
        dir_label="${dir_label:-.}"
        llm_desc="$(llm_describe_file "$rel" "$abs_file" "$raw_url" "$dir_label" "$REPO_SLUG" || true)"
        if [[ -n "$llm_desc" ]]; then
          desc="$llm_desc"
          sleep "$LLM_SLEEP_SEC"
        fi
      fi
    fi

    # Always construct the output line (avoid referencing unset vars under set -u)
    line="- [${title}](${raw_url}): ${desc}"
    dir_rel="$(dirname "$rel")"
    dir_rel="${dir_rel:-.}"
    append_to_dir "$dir_rel" "$line"
  done < <(find "${find_args[@]}")
done

# Print mapping grouped by folders (sorted)
if [[ -s "$DIR_LIST" ]]; then
  sort -u "$DIR_LIST" | while IFS= read -r dir_rel; do
    key="$(sanitize_dir "$dir_rel")"
    file="${SECTION_TMP_DIR}/dir_${key}.txt"
    [[ -s "$file" ]] || continue
    write_line ""
    # Show root as "/"
    header_label="$dir_rel"
    [[ "$header_label" = "." ]] && header_label="/"
    write_line "## ${header_label}"
    if [[ -z "${OUTPUT_SINK:-}" ]]; then
      cat "$file"
    else
      cat "$file" >> "$OUTPUT_SINK"
    fi
  done
fi

# If we cloned, move the output file back to original directory (already done via OUTPUT default)
if [[ -n "$TEMP_CLONE_DIR" ]]; then
  cd "$ORIGINAL_PWD"
fi

if [[ -n "${OUTPUT_PATH}" && -n "${OUTPUT_SINK:-}" ]]; then
  mv "$OUTPUT_SINK" "$OUTPUT_PATH"
  echo "Wrote ${OUTPUT_PATH}" >&2
fi


