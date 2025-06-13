# Clix iOS SDK

Clix iOS SDK is a powerful tool for managing push notifications and user events in your iOS application. It provides a simple and intuitive interface for user engagement and analytics.

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/clix-so/clix-ios-sdk.git", from: "1.0.0")
]
```

### CocoaPods

```ruby
pod 'Clix'
```

## Requirements

- iOS 14.0 or later
- Swift 5.5 or later

## Usage

### Initialization

Initialize the SDK with a ClixConfig object. The config is required and contains your project settings.

```swift
import Clix

let config = ClixConfig(
    projectId: "YOUR_PROJECT_ID",
    apiKey: "YOUR_API_KEY",
    endpoint: "https://api.clix.so", // Optional: default is https://api.clix.so
    logLevel: .debug, // Optional: set log level
    extraHeaders: [:] // Optional: extra headers for API requests
)

await Clix.initialize(config: config)
```

### Async/Await vs Synchronous API

All SDK methods provide both async/await and synchronous versions. The async versions are recommended for better control over operation timing.

```swift
// Async version (recommended)
try await Clix.setUserId("user123")

// Synchronous version
Clix.setUserId("user123")
```

### User Management

```swift
// Set user ID
try await Clix.setUserId("user123")

// Set user properties
try await Clix.setUserProperty("name", value: "John Doe")
try await Clix.setUserProperties([
    "age": 25,
    "premium": true
])

// Remove user properties
try await Clix.removeUserProperty("name")
try await Clix.removeUserProperties(["age", "premium"])

// Remove user ID
try await Clix.removeUserId()
```

### Device Information

```swift
// Get device ID
let deviceId = await Clix.getDeviceId()

// Get push token
let pushToken = await Clix.getPushToken()
```

### Logging

```swift
Clix.setLogLevel(.debug)
// Available log levels:
// - .none: No logs
// - .error: Error logs only
// - .warn: Warning logs
// - .info: Info logs
// - .debug: Debug logs
```

### Push Notification Integration

Clix SDK supports push notification integration via `ClixAppDelegate`.

#### Using ClixAppDelegate

This approach automates push notification registration, permission requests, device token management, and event
tracking.

1. **Enable Push Notifications in Xcode**
    - In your project, go to **Signing & Capabilities**.
    - Add **Push Notifications** and **Background Modes** (check Remote notifications).

2. **Inherit from ClixAppDelegate in your AppDelegate**

```swift
import UIKit
import Clix

@main
class AppDelegate: ClixAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Initialize Clix SDK after calling super
        Task {
            let config = ClixConfig(
                projectId: "YOUR_PROJECT_ID",
                apiKey: "YOUR_API_KEY",
                logLevel: .debug
            )
            await Clix.initialize(config: config)
        }
        
        return result
    }

    // Optional: Customize foreground notification presentation
    override func notificationDeliveredInForeground(
        notification: UNNotification
    ) -> UNNotificationPresentationOptions {
        return super.notificationDeliveredInForeground(notification: notification)
    }

    // Optional: Handle notification tap
    override func notificationTapped(userInfo: [AnyHashable: Any]) {
        super.notificationTapped(userInfo: userInfo)
        // Custom handling
    }

    // Optional: Handle silent notifications
    override func notificationDeliveredSilently(
        payload: [AnyHashable: Any],
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        super.notificationDeliveredSilently(payload: payload, completionHandler: completionHandler)
        // Custom handling
    }
}
```

- Permission requests, device token registration, and event tracking are handled automatically.
- Image notifications are automatically processed and displayed.
- Firebase integration is handled internally.
- Always call super to retain default SDK behavior.

### Notification Service Extension (Optional)

For rich push notifications with images, you can add a Notification Service Extension:

1. **Add Notification Service Extension target to your app**
2. **Inherit from ClixNotificationServiceExtension**

```swift
import UserNotifications
import Clix

class NotificationService: ClixNotificationServiceExtension {
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        // Register with your project ID
        register(projectId: "YOUR_PROJECT_ID")
        
        // Call super to handle image processing and event tracking
        super.didReceive(request, withContentHandler: contentHandler)
    }
}
```

## Sample App

A comprehensive sample app is provided in the `Samples/BasicApp` directory. You can open `BasicApp.xcodeproj` and run the app on a simulator or device. The sample demonstrates:

- Basic Clix SDK integration
- Push notification handling with Firebase
- User property management

To run the sample:
1. Open `Samples/BasicApp/BasicApp.xcodeproj`
2. Update the configuration in `ClixConfiguration.swift` with your project details
3. Add your `GoogleService-Info.plist` file
4. Run the app

## Error Handling

All SDK operations can throw `ClixError`. Always handle potential errors:

```swift
do {
    try await Clix.setUserId("user123")
} catch {
    print("Failed to set user ID: \(error)")
}
```

## Thread Safety

The SDK is thread-safe and all operations can be called from any thread. Async operations will automatically wait for SDK initialization to complete.

## License

This project is licensed under the MIT License with Custom Restrictions. See the [LICENSE](LICENSE) file for details.

## Changelog

See the full release history and changes in the [CHANGELOG.md](CHANGELOG.md) file.

## Contributing

We welcome contributions! Please read the [CONTRIBUTING.md](CONTRIBUTING.md) guide before submitting issues or pull requests.
