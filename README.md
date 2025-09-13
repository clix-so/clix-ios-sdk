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

- iOS 15.0 or later
- Swift 5.5 or later

## Breaking Changes

### Firebase 12+ Support
If you need to use Firebase 12 or later, you must use the latest version of Clix iOS SDK. Previous versions may not be compatible with Firebase 12+.

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

Clix SDK supports two integration paths:
- `ClixAppDelegate` subclassing (quick start, minimal code)
- `Clix.Notification` static helper (manual wiring, fine-grained control)

#### Using ClixAppDelegate

This approach automates push notification registration, permission requests, device token management, and event tracking.

1. **Enable Push Notifications in Xcode**
    - In your project, go to **Signing & Capabilities**.
    - Add **Push Notifications** and **Background Modes** (check Remote notifications).

2. **Inherit from ClixAppDelegate in your AppDelegate**

##### Quick Start (Defaults)

If you want the quickest working setup with sensible defaults, subclass `ClixAppDelegate` and initialize the SDK. Firebase is only needed if you use FCM.

```swift
import UIKit
import Clix
import Firebase

@main
class AppDelegate: ClixAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

        FirebaseApp.configure()

        // Required: initialize Clix with your credentials
        Task {
            let config = ClixConfig(
                projectId: "YOUR_PROJECT_ID",
                apiKey: "YOUR_API_KEY"
            )
            await Clix.initialize(config: config)
        }

        return result
    }
}
```

##### Advanced Customization (Override Hooks)

```swift
import UIKit
import Firebase
import Clix

@main
class AppDelegate: ClixAppDelegate {
    // Optional: delay the system permission prompt until your onboarding is ready.
    // Remove or change to `true` to use SDK default behavior.
    override var autoRequestAuthorizationOnLaunch: Bool { false }

    // Optional: prevent automatic deep-link opening on push tap; route manually instead.
    // Remove or change to `true` to use SDK default behavior.
    override var autoOpenLandingOnTap: Bool { false }

    // Optional: force foreground presentation options instead of SDK logic.
    override func willPresentOptions(for notification: UNNotification) -> UNNotificationPresentationOptions? {
        if #available(iOS 14.0, *) { return [.list, .banner, .sound, .badge] }
        else { return [.alert, .sound, .badge] }
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

        // Configure Firebase
        FirebaseApp.configure()

        // Initialize Clix SDK after calling super.
        Task {
            let config = ClixConfig(
                projectId: "YOUR_PROJECT_ID",
                apiKey: "YOUR_API_KEY",
                logLevel: .debug
            )
            await Clix.initialize(config: config)
        }

        // Optional: since autoOpenLandingOnTap is set to false above, handle routing yourself if needed.
        Clix.Notification.setNotificationOpenedHandler { userInfo in
            if let clix = userInfo["clix"] as? [String: Any],
               let urlStr = clix["landing_url"] as? String,
               let url = URL(string: urlStr) {
                UIApplication.shared.open(url)
            }
        }

        // Optional: when autoRequestAuthorizationOnLaunch is false, show the prompt later:
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
          if granted { DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() } }
        }

        return result
    }

    // Optional: override foreground notifications handler and forward to SDK.
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Use SDK default logic (images, analytics) and just forward.
        Clix.Notification.handleWillPresent(notification: notification, completionHandler: completionHandler)

        // Or, force custom options regardless of SDK logic:
        // completionHandler([.banner, .sound, .badge])
    }

    // Optional: override background notifications handler.
    override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification payload: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Wrap the completion to add your own work.
        Clix.Notification.handleBackgroundNotification(payload) { result in
            // Custom background work (e.g., refresh local cache)
            completionHandler(result)
        }
    }

    // Optional: override notification tap event handler.
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Forward to Clix to keep analytics and deep link behavior consistent.
        Clix.Notification.handleDidReceive(response: response, completionHandler: completionHandler)
    }
}
```

- Permission requests, device token registration, and event tracking are handled automatically.
- Rich images: for best reliability use a Notification Service Extension. In foreground, the SDK can attach images and re-post the notification when possible.
- Firebase is required, call `FirebaseApp.configure()` during app launch.
- Always call super to retain default SDK behavior where indicated.

#### Using Clix.Notification

If you prefer not to inherit from `ClixAppDelegate` or need more control over your AppDelegate implementation, you can use the static `Clix.Notification` helpers to handle APNs/FCM wiring and lifecycle callbacks.

```swift
import SwiftUI
import UIKit
import Firebase
import FirebaseMessaging
import Clix

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene { WindowGroup { ContentView() } }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()

        // Initialize Clix SDK
        let config = ClixConfig(projectId: "YOUR_PROJECT_ID", apiKey: "YOUR_API_KEY", logLevel: .debug)
        Clix.initialize(config: config)

        // Set UNUserNotificationCenter delegate if you need to intercept callbacks
        UNUserNotificationCenter.current().delegate = self

        // Setup push via Clix.Notification (delay prompt optional)
        Clix.Notification.setup()
        Clix.Notification.handleLaunchOptions(launchOptions)

        // Optional: customize foreground presentation and tap handling
        Clix.Notification.setNotificationWillShowInForegroundHandler { _ in
            if #available(iOS 14.0, *) { return [.list, .banner, .sound, .badge] }
            else { return [.alert, .sound, .badge] }
        }
        Clix.Notification.setNotificationOpenedHandler { userInfo in
            // Custom routing (also see setAutoOpenLandingOnTap below)
            if let clixData = userInfo["clix"] as? [String: Any],
               let landingURL = clixData["landing_url"] as? String,
               let url = URL(string: landingURL) {
                UIApplication.shared.open(url)
            }
        }
        // Optional: control whether SDK auto-opens deep links on tap, default true.
        Clix.Notification.setAutoOpenLandingOnTap(true)

        return true
    }

    // MARK: - APNs/FCM registration
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Clix.Notification.handleAPNSToken(deviceToken)
    }
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Clix.Notification.handleAPNSRegistrationError(error)
    }

    // MARK: - Background/foreground receipt
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        Clix.Notification.handleForegroundNotification(userInfo)
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification payload: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Clix.Notification.handleBackgroundNotification(payload, completionHandler: completionHandler)
    }

    // MARK: - UNUserNotificationCenterDelegate (optional)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Forward to SDK for consistent image handling and analytics
        Clix.Notification.handleWillPresent(notification: notification, completionHandler: completionHandler)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        Clix.Notification.handleDidReceive(response: response, completionHandler: completionHandler)
    }
}
```

##### Clix.Notification quick reference
- `setup(autoRequestAuthorization: Bool)`: 푸시 권한 요청 타이밍 선택(기본 true)
- `handleLaunchOptions(_:)`: 푸시로 앱 실행된 경우 초기 처리
- `handleAPNSToken(_:)`, `handleAPNSRegistrationError(_:)`: APNs 등록 결과 전달
- `handleBackgroundNotification(_:completionHandler:)`: 백그라운드 수신 처리 및 completion 호출
- `handleForegroundNotification(_:)`: 포그라운드 수신 분석 처리(자동 딥링크 오픈 없음)
- `setNotificationWillShowInForegroundHandler(_:)`: 포그라운드 표시 옵션 커스터마이즈
- `setNotificationOpenedHandler(_:)`: 탭 후 후속 처리(로그/라우팅)
- `setAutoOpenLandingOnTap(_:)`: 탭 시 SDK가 딥링크 자동 오픈 여부 제어
- `handleWillPresent(notification:completionHandler:)`: UNUserNotificationCenterDelegate 포워딩 헬퍼
- `handleDidReceive(response:completionHandler:)`: UNUserNotificationCenterDelegate 포워딩 헬퍼


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
