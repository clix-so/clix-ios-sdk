# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.7.0] - 2026-01-16

### Added

- **Live Activity**
  - Added `Clix.LiveActivity` for Live Activity push-to-start token management (iOS 17.2+)
  - Automatically listens for push-to-start tokens and syncs with backend
  - Usage: `Clix.LiveActivity.setup(YourActivityAttributes.self)`

## [1.6.0] - 2025-12-03

### Added

- **Storage**
  - Integrated MMKV for high-performance storage (~30x faster than UserDefaults)
  - Added automatic migration from UserDefaults to MMKV with automatic cleanup
  - Added App Group migration from projectId-based to bundleId-based

### Changed

- **Storage**
  - Refactored storage layer with `Storage` protocol abstraction
  - Updated App Group identifier format: `group.clix.{projectId}` → `group.clix.{bundleId}`

- **App Extension Compatibility**
  - `Clix.Notification` is now unavailable in app extensions (use SDK initialization directly in extensions)

### Fixed

- **Notification Service Extension**
  - Fixed race condition where notifications could be processed before SDK initialization completes

- **Storage**
  - Improved storage migration and initialization stability to prevent crashes

## [1.5.3] - 2025-11-20

### Changed

- **Push Notifications**
  - Renamed notification APIs for cross-platform consistency:
    - `setup()` → `configure(autoRequestPermission:autoHandleLandingURL:)`
    - `setNotificationWillShowInForegroundHandler()` → `onMessage()`
    - `setNotificationOpenedHandler()` → `onNotificationOpened()`
    - `handleAPNSToken()` → `setApnsToken()`
    - `requestNotificationPermission()` → `requestPermission()`
    - `autoRequestAuthorizationOnLaunch` → `autoRequestPermission`
    - `autoOpenLandingOnTap` → `autoHandleLandingURL`
  - All previous APIs remain available with deprecation warnings for backward compatibility.

### Added

- **Push Notifications**
  - Added `onApnsTokenError()` handler for APNs token registration errors.
  - Added `autoHandleLandingURL` parameter to `configure()` method.

## [1.5.2] - 2025-11-18

### Changed

- **Push Notifications**
  - Renamed `autoRequestAuthorizationOnLaunch`/`autoRequestAuthorization` to `autoRequestPermissionOnLaunch`/`autoRequestPermission` with deprecated aliases for backward compatibility.
  - Changed `Clix.Notification.requestNotificationPermission` to public.

## [1.5.1] - 2025-11-17

### Changed

- Updated internal payload structure for improved data handling

## [1.5.0] - 2025-11-17

### Added

- **Push Notifications**
  - Added `setPushPermissionGranted(_:)` method to manually update push permission status

### Changed

- **Push Notifications**
  - Changed `autoRequestAuthorizationOnLaunch` default value from `true` to `false`

### Fixed

- **Push Notifications**
  - Improved duplicate event tracking prevention with message ID deduplication

## [1.4.1] - 2025-10-18

### Fixed

- **Push Notifications**
  - Prevented duplicate `PUSH_NOTIFICATION_RECEIVED` tracking when both the notification service extension and application process handle the same message id.

## [1.4.0] - 2025-10-15

### Added

- **Event Tracking**
  - Exposed `trackEvent` for public integrations.
  - Normalized event property values for consistent payloads.

### Fixed

- **Push Notifications**
  - Ensured push tokens are issued even when users decline permissions.

## [1.3.0] - 2025-09-13

### Added

- **User Properties**

  - Added datetime property type support with automatic ISO8601 formatting

- **Push Notifications**
  - Added `Clix.Notification` static helper for manual integration (alternative to ClixAppDelegate)
  - Added configurable override points in ClixAppDelegate (auto-authorization, auto-deeplink, presentation options)

### Changed

- **Push Notifications**
  - Refactored notification handling logic into separate ClixNotification class
  - Improved SDK initialization resilience with fallback configuration handling

## [1.2.0] - 2025-09-04

### Added

- **Event Tracking**
  - Added user journey context to event properties for statistics

## [1.1.1] - 2025-08-28

### Fixed

- **Push Notifications**
  - Fixed duplicate token processing issue that could cause unnecessary API calls

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
