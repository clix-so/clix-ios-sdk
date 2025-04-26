# Clix iOS SDK

Clix iOS SDK is a powerful toolkit for managing push notifications and tracking user events in iOS applications. It provides a simple and intuitive interface for handling user engagement and analytics.

## Installation

### Swift Package Service

```swift
dependencies: [
    .package(url: "https://github.com/clix-so/clix-ios-sdk.git", from: "1.0.0")
]
```

### CocoaPods

```ruby
pod 'Clix'
```

## Usage

### Initialization

```swift
import Clix

// Initialize the SDK
let config = ClixConfig(
    apiKey: "YOUR_API_KEY",
    endpoint: "https://api.clix.so", // Optional: defaults to https://api.clix.so
    logLevel: .debug // Optional: set logging level
)

Task {
    try await Clix.shared.initialize(
        apiKey: "YOUR_API_KEY",
        endpoint: "https://api.clix.so",
        withConfig: config
    )
}
```

### User Management

```swift
// Set User ID
Task {
    try await Clix.shared.setUserId("user123")
}

// Remove User ID
Task {
    try await Clix.shared.removeUserId()
}

// Set User Attributes
Task {
    try await Clix.shared.setAttribute("name", value: "John Doe")
}
```

### Event Tracking

```swift
// Track Events
Task {
    try await Clix.shared.trackEvent("button_clicked", properties: [
        "button_id": "login_button",
        "screen": "login"
    ])
}
```

### Push Notification Integration

Add these methods to your `AppDelegate` or relevant SwiftUI lifecycle handlers:

```swift
// Handle device token registration
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Task {
        try? await Clix.shared.handleDeviceToken(deviceToken)
    }
}

// Handle registration failures
func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    Clix.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
}

// Handle incoming notifications
func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    Clix.shared.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
}

// Handle notification responses
func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    Clix.shared.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
}
```

### Device Token Management

```swift
// Get current device token
let currentToken = Clix.getCurrentToken()

// Get previous device tokens
let previousTokens = Clix.getPreviousTokens()
```

### Logging

```swift
// Set logging level
Clix.setLogLevel(.debug)
```

### Reset

```swift
// Reset SDK state
Clix.shared.reset()
```

## Features

- Easy integration with Swift Package Service and CocoaPods
- Comprehensive push notification handling
- User identification and attribute management
- Event tracking with custom properties
- Device token management
- Configurable logging levels
- Async/await support for modern Swift development
- Automatic permission handling for notifications

## License

This project is distributed under the MIT License. See the [LICENSE](LICENSE) file for more details.
