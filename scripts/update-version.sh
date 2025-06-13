#!/bin/sh

# Script that updates the Clix iOS SDK version in both Swift source code and CocoaPods spec file.
#
# This script updates:
# 1. ClixVersion.swift - The Swift file containing the SDK version
# 2. Clix.podspec - The CocoaPods specification file
#
# Usage: ./scripts/update-version.sh "1.0.0"

set -e

NEW_VERSION="$1"

if [ -z "$NEW_VERSION" ]; then
    echo "Error: Version number is required"
    echo "Usage: ./scripts/update-version.sh \"1.0.0\""
    exit 1
fi

RELATIVE_PATH_TO_SCRIPTS_DIR=$(dirname "$0")
ABSOLUTE_PATH_TO_ROOT_DIR=$(realpath "$RELATIVE_PATH_TO_SCRIPTS_DIR/..")

# File paths
SWIFT_SOURCE_FILE="$ABSOLUTE_PATH_TO_ROOT_DIR/Sources/Core/ClixVersion.swift"
PODSPEC_FILE="$ABSOLUTE_PATH_TO_ROOT_DIR/Clix.podspec"

echo "🔄 Updating Clix iOS SDK to version: $NEW_VERSION"
echo ""

# 1. Update ClixVersion.swift
echo "📝 Updating Swift source file: $SWIFT_SOURCE_FILE"
if [ ! -f "$SWIFT_SOURCE_FILE" ]; then
    echo "Error: Swift source file not found at $SWIFT_SOURCE_FILE"
    exit 1
fi

# Use sed to replace the version string in ClixVersion.swift
# Pattern matches: `internal static let current: String = "1.0.0"`
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS version of sed
    sed -i '' "s/internal static let current: String = \".*\"/internal static let current: String = \"$NEW_VERSION\"/" "$SWIFT_SOURCE_FILE"
else
    # Linux version of sed
    sed -i "s/internal static let current: String = \".*\"/internal static let current: String = \"$NEW_VERSION\"/" "$SWIFT_SOURCE_FILE"
fi

echo "✅ Updated ClixVersion.swift"
echo ""

# 2. Update Clix.podspec
echo "📝 Updating Clix.podspec: $PODSPEC_FILE"
if [ ! -f "$PODSPEC_FILE" ]; then
    echo "Error: Podspec file not found at $PODSPEC_FILE"
    exit 1
fi

# Use sed to replace the version string in Clix.podspec
# Pattern matches: `spec.version          = '1.0.0'` with optional comment
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS version of sed
    sed -i '' "s/spec\.version.*=.*'[^']*'.*/spec.version          = '$NEW_VERSION' # Don't modify this line - it's automatically updated by scripts\/update-version.sh/" "$PODSPEC_FILE"
else
    # Linux version of sed
    sed -i "s/spec\.version.*=.*'[^']*'.*/spec.version          = '$NEW_VERSION' # Don't modify this line - it's automatically updated by scripts\/update-version.sh/" "$PODSPEC_FILE"
fi

echo "✅ Updated Clix.podspec"
echo ""

# Show changes
echo "🔍 Showing changes to confirm they worked:"
echo ""

echo "--- Changes to ClixVersion.swift ---"
git --no-pager diff "$SWIFT_SOURCE_FILE" || echo "No git repository or no changes detected"
echo ""

echo "--- Changes to Clix.podspec ---"
git --no-pager diff "$PODSPEC_FILE" || echo "No git repository or no changes detected"
echo ""

echo "🎉 Version update completed successfully!"
echo "📦 New version: $NEW_VERSION"
echo ""
echo "Next steps:"
echo "1. Review the changes above"
echo "2. Run tests: make test"
echo "3. Commit changes: git add . && git commit -m \"chore: bump version to $NEW_VERSION\""
echo "4. Create tag: git tag $NEW_VERSION"
echo "5. Push: git push origin main --tags" 
