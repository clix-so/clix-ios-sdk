# Clix iOS SDK

Clix iOS SDK is a powerful tool for managing push notifications and user events in your iOS application. It provides a simple and intuitive interface for user engagement and analytics.

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/clix-so/clix-ios-sdk.git", from: "1.5.2")
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

### Event Tracking

```swift
// Track an event with properties
try await Clix.trackEvent(
  "signup_completed",
  properties: [
    "method": "email",
    "discount_applied": true,
    "trial_days": 14,
    "completed_at": Date()
  ]
)
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
        // Configure Firebase first (before calling super)
        FirebaseApp.configure()

        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

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
    // SDK default is `false`. Override to `true` to auto-request permissions on launch.
    override var autoRequestPermissionOnLaunch: Bool { true }

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
        // Configure Firebase first (before calling super)
        FirebaseApp.configure()

        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

        // Initialize Clix SDK
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

        // Optional: when autoRequestPermissionOnLaunch is false, show the prompt later:
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
          // Notify Clix SDK about permission status
          Clix.setPushPermissionGranted(granted)

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
- **Important:** Firebase must be configured **before** calling `super.application()` to ensure proper token collection.
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

- `setup(autoRequestPermission: Bool)`: Choose push permission request timing (default true)
- `handleLaunchOptions(_:)`: Handle initial processing when app is launched via push
- `handleAPNSToken(_:)`, `handleAPNSRegistrationError(_:)`: Forward APNs registration results
- `handleBackgroundNotification(_:completionHandler:)`: Handle background notification receipt and call completion
- `handleForegroundNotification(_:)`: Handle foreground notification analytics (no automatic deep link opening)
- `setNotificationWillShowInForegroundHandler(_:)`: Customize foreground display options
- `setNotificationOpenedHandler(_:)`: Handle post-tap processing (logging/routing)
- `setAutoOpenLandingOnTap(_:)`: Control whether SDK automatically opens deep links on tap
- `handleWillPresent(notification:completionHandler:)`: UNUserNotificationCenterDelegate forwarding helper
- `handleDidReceive(response:completionHandler:)`: UNUserNotificationCenterDelegate forwarding helper

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

## Troubleshooting

### Push Token Not Being Collected

If you notice that push tokens (FCM tokens) are not being collected in the Clix console, check the following:

#### 1. Firebase Must Be Configured Before super.application

When using `ClixAppDelegate`, ensure `FirebaseApp.configure()` is called **before** `super.application(application, didFinishLaunchingWithOptions: launchOptions)`:

```swift
@main
class AppDelegate: ClixAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // ✅ Configure Firebase FIRST
        FirebaseApp.configure()

        // ✅ Then call super
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

        // Initialize Clix SDK
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

**Why this matters:** The SDK's `super.application` internally references the Firebase instance, so Firebase must be initialized first.

#### 2. Forward FCM Token to Clix SDK

If you implement `MessagingDelegate`, you must forward the FCM token to Clix:

```swift
import FirebaseMessaging

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // ✅ Forward token to Clix SDK
        Clix.Notification.messaging(messaging, didReceiveRegistrationToken: fcmToken)

        // Your custom logic here
        Task {
            guard let fcmToken else { return }
            // Handle token as needed
        }
    }
}
```

#### 3. Do NOT Override Messaging Delegate Directly

**Avoid** setting `Messaging.messaging().delegate = self` in your AppDelegate when using `ClixAppDelegate`:

```swift
// ❌ DON'T DO THIS
Messaging.messaging().delegate = self
```

**Why:** Clix SDK internally sets `Messaging.messaging().delegate = ClixNotification.shared` to collect FCM tokens. If you override this, token collection will fail.

If you need custom `MessagingDelegate` behavior, implement the delegate methods and forward to Clix as shown in step 2.

#### 4. Enable Debug Logging

To verify token collection, enable debug logging:

```swift
let config = ClixConfig(
    projectId: "YOUR_PROJECT_ID",
    apiKey: "YOUR_API_KEY",
    logLevel: .debug  // Enable debug logs
)
await Clix.initialize(config: config)
```

Look for these log messages in Xcode console:

- `[Clix] FCM registration token received: ...`
- `[Clix] FCM token successfully processed after SDK initialization`

### Push Permission Status Not Updating

If you've disabled automatic permission requests (`autoRequestPermissionOnLaunch = false`), you must manually notify Clix when users grant or deny push permissions.

#### Update Permission Status

After requesting push permissions in your app, call `Clix.setPushPermissionGranted()`:

```swift
UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
    if let error = error {
        print("Permission request error: \(error)")
        return
    }

    // ✅ Notify Clix SDK about permission status
    Clix.setPushPermissionGranted(granted)

    if granted {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
```

**Note:** This method is available in SDK version 1.5.0 and later.

### Debugging Checklist

If push notifications aren't working, verify:

1. ✅ Push Notifications capability is enabled in Xcode project settings
2. ✅ Background Modes > Remote notifications is enabled
3. ✅ `FirebaseApp.configure()` is called before `super.application` (when using `ClixAppDelegate`)
4. ✅ `Clix.Notification.messaging()` is called in `MessagingDelegate` (if implementing custom delegate)
5. ✅ NOT setting `Messaging.messaging().delegate = self` when using `ClixAppDelegate`
6. ✅ `Clix.setPushPermissionGranted()` is called after requesting permissions (when using `autoRequestPermissionOnLaunch = false`)
7. ✅ Testing on a real device (push notifications don't work on iOS 26 simulator)
8. ✅ Debug logs show "FCM registration token received" message

### Getting Help

If you continue to experience issues:

1. Enable debug logging (`.debug` log level)
2. Check Xcode console for Clix log messages
3. Verify your device appears in the Clix console Users page
4. Check if `push_token` field is populated for your device
5. Create an issue on [GitHub](https://github.com/clix-so/clix-ios-sdk/issues) with logs and configuration details

## License

This project is licensed under the MIT License with Custom Restrictions. See the [LICENSE](LICENSE) file for details.

## Changelog

See the full release history and changes in the [CHANGELOG.md](CHANGELOG.md) file.

## Contributing

We welcome contributions! Please read the [CONTRIBUTING.md](CONTRIBUTING.md) guide before submitting issues or pull requests.
