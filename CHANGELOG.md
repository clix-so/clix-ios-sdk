# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-08-21

### Changed

- **Compatibility**
  - Updated minimum iOS deployment target from 14.0 to 15.0
  - Updated Swift Package Manager platform requirement to iOS 15.0
  - Updated CocoaPods deployment target to iOS 15.0

## [1.0.0] - 2025-06-01

### Added

- **Core SDK**
  - ClixConfig-based initialization with projectId, apiKey, endpoint configuration
  - Async/await and synchronous API support
  - Thread-safe operations with automatic initialization handling

- **User Management**
  - User identification: `setUserId()`, `removeUserId()`
  - User properties: `setUserProperty()`, `setUserProperties()`, `removeUserProperty()`

- **Push Notifications**
  - Firebase Cloud Messaging integration
  - ClixAppDelegate for automated push notification handling
  - ClixNotificationServiceExtension for rich notifications with images
  - Automatic device token management

- **Device & Logging**
  - Device information access: `getDeviceId()`, `getPushToken()`
  - Configurable logging system with 5 levels (none to debug)

- **Installation**
  - Swift Package Manager and CocoaPods support
  - iOS 14.0+ and Swift 5.5+ compatibility
  - Sample app with complete integration example
