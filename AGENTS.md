# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Clix iOS SDK is a Swift Package Manager library for managing push notifications, user events, and device management in iOS applications. It provides both AppDelegate subclassing (`ClixAppDelegate`) and manual integration (`Clix.Notification`) patterns for push notification handling.

**Key Technologies:**
- Swift 5.5+ (async/await)
- iOS 15.0+ deployment target
- Firebase Messaging for FCM token management
- UserNotifications framework for push notifications
- Swift Package Manager

## Development Commands

### Building
```bash
# Build for iOS devices (arm64)
make build

# Clean build artifacts and caches
make clean
```

### Code Quality
```bash
# Format code with swift-format
make format

# Lint code with SwiftLint
make lint

# Auto-fix linting issues
make lint-fix

# Run both format and lint-fix
make all
```

### Testing
```bash
# Run tests
swift test
```

### CI/CD
- CI runs on `macos-15` runner
- CI workflow: lint → build
- CI triggers on PRs to `main` (excludes `Samples/` and `README.md`)

## Architecture

### Core Layer (`Sources/Core/`)
The SDK follows a singleton pattern with lazy service initialization:

- **`Clix`**: Main entry point, singleton (`Clix.shared`)
  - Manages SDK initialization via `InitCoordinator` for thread-safe async/sync patterns
  - Exposes both async (`await`) and synchronous APIs
  - All public APIs wait for initialization to complete before executing

- **`ClixConfig`**: Configuration object (projectId, apiKey, endpoint, logLevel, extraHeaders)

- **`ClixEnvironment`**: Holds runtime state (config + device)

- **`ClixNotification`**: Singleton notification manager (`Clix.Notification`)
  - Implements `UNUserNotificationCenterDelegate` and `MessagingDelegate`
  - Handles APNs/FCM token management, notification events, and deep links
  - Provides both auto-handling and manual routing options

- **`ClixAppDelegate`**: Base AppDelegate class for quick integration
  - Subclass to get automatic push notification setup
  - Override points: `autoRequestPermission`, `autoHandleLandingURL`, `willPresentOptions(for:)`
  - **Critical**: `FirebaseApp.configure()` must be called BEFORE `super.application()` to ensure FCM tokens are collected

### Service Layer (`Sources/Services/`)
Services are lazily initialized during SDK initialization:

- **`StorageService`**: UserDefaults wrapper for persistent storage (device ID, user properties, push tokens)
- **`TokenService`**: Manages device ID generation and persistence
- **`DeviceService`**: User management (userId, userProperties) and device registration
- **`EventService`**: Event tracking and analytics
- **`NotificationService`**: Push notification payload processing and event tracking
- **`ClixAPIClient`**: HTTP client wrapper with project authentication headers
- **`DeviceAPIService`** / **`EventAPIService`**: API-specific services for device and event operations

### Models (`Sources/Models/`)
- **`ClixDevice`**: Device model (id, userId, pushToken, userProperties, permissions)
- **`ClixUserProperty`**: User property model
- **`ClixPushNotificationPayload`**: Notification payload structure

### Utilities (`Sources/Utils/`)
- **HTTP**: Custom HTTP client (`HTTPClient`, `HTTPRequest`, `HTTPResponse`, `HTTPMethod`)
- **Logging**: `ClixLogger` with configurable log levels (none, error, warn, info, debug)
- **AnyCodable**: Type-erased JSON encoding/decoding (`AnyCodable`, `AnyEncodable`, `AnyDecodable`)
- **ClixError**: SDK error types
- **ClixDateFormatter** / **ClixJSONCoders**: Shared formatters and coders

### Notification Extension (`Sources/Notification/`)
- **`ClixNotificationServiceExtension`**: Base class for Notification Service Extension
  - Handles rich push notifications with image attachments
  - Must call `register(projectId:)` in `didReceive(_:withContentHandler:)`

## Critical Integration Patterns

### Firebase Token Collection
The SDK internally sets `Messaging.messaging().delegate = ClixNotification.shared` to collect FCM tokens. If you implement a custom `MessagingDelegate`:

```swift
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // MUST forward to SDK
        Clix.Notification.messaging(messaging, didReceiveRegistrationToken: fcmToken)
        // Your custom logic
    }
}
```

**Never** override `Messaging.messaging().delegate = self` when using `ClixAppDelegate` - token collection will fail.

### Initialization Coordinator
`InitCoordinator` synchronizes SDK initialization across threads:
- Async APIs: `await Clix.initialize()` then direct execution
- Sync APIs: Background initialization + `waitAndGet()` pattern
- All operations block until initialization completes to prevent race conditions

### Push Notification Flow
1. APNs token → `setApnsToken()` → StorageService
2. FCM token → `MessagingDelegate` → Device registration API
3. Notification received → `NotificationService.process()` → Event tracking
4. Notification tapped → `handleNotificationTapped()` → Deep link handling + event tracking

## Code Style

- Configured with `.swift-format` and `.swiftlint.yml`
- Always run `make format` before committing
- SwiftLint enforces file length, line length, and Swift conventions
- Run `make lint-fix` to auto-fix issues

## Sample App

Located in `Samples/BasicApp/` directory:
- Demonstrates SDK integration with Firebase
- Requires `ClixConfiguration.swift` update with project credentials
- Requires `GoogleService-Info.plist` file

## Important Notes

- **Thread Safety**: All public APIs are thread-safe, services handle concurrent access
- **Async/Await**: Prefer async APIs (`try await Clix.setUserId()`) over sync versions
- **Firebase Dependency**: SDK requires Firebase 10.0.0 - 19.x (supports Firebase 12+)
- **iOS Simulator**: Push notifications don't work on iOS 26 simulator, test on real devices
- **Permission Status**: When `autoRequestPermission: false`, manually call `Clix.setPushPermissionGranted()` after requesting permissions
- **Background Modes**: Enable "Remote notifications" in Background Modes capability for background push handling

## Common Development Patterns

### Adding New API Endpoints
1. Add method to `ClixAPIClient` (get/post/patch/delete)
2. Create specific service in `Services/` (e.g., `DeviceAPIService`)
3. Expose via `Clix` or `Clix.Notification` public API
4. Add async and optional sync versions
5. Handle errors with `ClixError` types

### Modifying Device State
- Device state lives in `ClixEnvironment.device`
- Update via `DeviceService` methods
- Persist to `StorageService` for offline support
- Sync to API via `DeviceAPIService`

### Handling New Notification Events
- Process payload in `NotificationService.process()`
- Track event via `EventService.trackEvent()`
- Update notification state in `ClixNotification` if needed

## Breaking Changes

- Firebase 12+ support requires latest SDK version (1.5.3+)
- Older versions may not be compatible with Firebase 12+
