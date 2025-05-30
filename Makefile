# Makefile for Swift code formatting and linting

# Define phony targets to avoid conflicts with files named format or lint
.PHONY: build clean format lint lint-fix all

# Target to build the Swift package for iOS devices
build:
	@echo "Building Clix SDK for iOS using swift build..."
	@swift build \
	--triple arm64-apple-ios \
	-Xswiftc -sdk \
	-Xswiftc /var/db/xcode_select_link/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk \
	-Xcc -isysroot \
	-Xcc /var/db/xcode_select_link/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk

# Clean build artifacts and caches
clean:
	@echo "Cleaning build artifacts and caches..."
	@rm -rf .build .index-build ~/Library/Developer/Xcode/DerivedData


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
