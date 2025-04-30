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

- iOS 13.0 or later
- Swift 5.5 or later

## Usage

### Initialization

You can initialize the SDK with or without a configuration. The `config` parameter is optional.

**Without config:**

```swift
import Clix

await Clix.initialize(
    apiKey: "YOUR_API_KEY",
    endpoint: "https://api.clix.so", // Optional: default is https://api.clix.so
)
```

**With config:**

```swift
import Clix

let config = ClixConfig(
    logLevel: .debug // Optional: set log level
)

await Clix.initialize(
    apiKey: "YOUR_API_KEY",
    endpoint: "https://api.clix.so", // Optional: default is https://api.clix.so
    config: config
)
```

### User Management₩

```swift
await Clix.setUserId("user123")
await Clix.setProperty("name", value: "John Doe")
await Clix.setProperties([
    "age": 25,
    "premium": true
])
await Clix.removeProperty("name")
await Clix.removeUserId()
```

### Event Tracking

```swift
await Clix.trackEvent("button_clicked", properties: [
    "button_id": "login_button",
    "screen": "login"
])
```

### Reset SDK State

```swift
Clix.reset()
```

### Logging

```swift
Clix.setLogLevel(.debug)
// Available log levels:
// - .none: Disable logging
// - .error: Log errors only
// - .warning: Log warnings and errors
// - .info: Log info, warnings, and errors
// - .debug: Log all
```

### Push Notification Integration

Clix SDK supports push notification integration via `ClixAppDelegate`.

#### Using ClixAppDelegate

This approach automates push notification registration, permission requests, device token management, and event tracking.

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
        // Custom initialization
        return result
    }

    // Optional: Customize foreground notification presentation
    override func pushNotificationDeliveredInForeground(
        notification: UNNotification
    ) -> UNNotificationPresentationOptions {
        return super.pushNotificationDeliveredInForeground(notification: notification)
    }

    // Optional: Handle notification tap
    override func pushNotificationTapped(userInfo: [AnyHashable: Any]) {
        super.pushNotificationTapped(userInfo: userInfo)
        // Custom handling
    }
}
```

- Permission requests, device token registration, and event tracking are handled automatically.
- You can override: `pushNotificationDeliveredInForeground`, `pushNotificationTapped`, `pushNotificationDeliveredSilently`.
- Always call super to retain default SDK behavior.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Changelog

See the full release history and changes in the [CHANGELOG.md](CHANGELOG.md) file.

## Contributing

We welcome contributions! Please read the [CONTRIBUTING.md](CONTRIBUTING.md) guide before submitting issues or pull requests.
