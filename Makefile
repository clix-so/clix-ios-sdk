# Makefile for Swift code formatting and linting

# Define phony targets to avoid conflicts with files named format or lint
.PHONY: build test clean format lint lint-fix all

# Target to build the Swift package for iOS devices
build:
	@echo "Building Clix SDK for iOS using swift build..."
	@swift build \
        --triple arm64-apple-ios \
        -Xswiftc -sdk \
        -Xswiftc $(shell xcrun --sdk iphoneos --show-sdk-path) \
        -Xcc -isysroot \
        -Xcc $(shell xcrun --sdk iphoneos --show-sdk-path)

# Detect first available iPhone Simulator UDID
SIMULATOR_UDID := $(shell xcrun simctl list devices available | grep iPhone | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')

# Target to run tests on iOS Simulator
test:
	@echo "Running tests on iOS Simulator ($(SIMULATOR_UDID))..."
	@xcodebuild test \
        -workspace .swiftpm/xcode/package.xcworkspace \
        -scheme Clix \
        -destination 'id=$(SIMULATOR_UDID)' \
        -quiet

# Clean build artifacts and caches
clean:
	@echo "Cleaning build artifacts and caches..."
	@rm -rf .build .index-build ~/Library/Developer/Xcode/DerivedData
	@echo "Cleaning Package.resolved files..."
	@find . -name "Package.resolved" -type f -delete


# Target to format Swift code using swift-format
format:
	@echo "Formatting Swift code..."
	@swift format . --in-place --recursive

# Target to lint Swift code using SwiftLint
lint:
	@echo "Linting Swift code..."
	@swiftlint

# Target to automatically fix lint issues using SwiftLint
lint-fix:
	@echo "Fixing Swift lint issues..."
	@swiftlint --fix

# Target to run both formatting and linting
all: format lint-fix
