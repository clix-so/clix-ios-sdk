# BasicApp - Clix iOS SDK Sample

A sample iOS application demonstrating the integration and usage of the Clix iOS SDK for push notifications and user analytics.

## Features

- Push notification handling with Firebase Cloud Messaging (FCM)
- Rich push notifications with images via Notification Service Extension
- User identification and custom properties
- Event tracking
- Deep link handling from notifications
- SwiftUI-based user interface

## Prerequisites

- Xcode 15.0 or later
- iOS 15.0 or later
- Swift 5.5 or later
- Firebase project with Cloud Messaging enabled
- Clix project credentials

## Setup Instructions

### 1. Configure Firebase

1. Download your `GoogleService-Info.plist` from Firebase Console
2. Add it to `Samples/BasicApp/Resources/` directory

### 2. Configure Clix SDK

1. Copy the example configuration file:
   ```bash
   cp ClixConfig.json.example Resources/ClixConfig.json
   ```

2. Edit `Resources/ClixConfig.json` with your Clix project credentials:
   ```json
   {
     "projectId": "your-project-id",
     "apiKey": "your-api-key",
     "endpoint": "https://api.clix.so",
     "extraHeaders": {}
   }
   ```

### 3. Configure App Groups

The SDK uses App Groups to share data between the main app and Notification Service Extension.

1. **Main App Target (BasicApp)**:
   - Open Xcode → Select BasicApp target
   - Go to "Signing & Capabilities" tab
   - Click "+ Capability" → Add "App Groups"
   - Add group: `group.clix.so.clix.samples.basic`

2. **Notification Service Extension Target (ClixNotificationExtension)**:
   - Select ClixNotificationExtension target
   - Go to "Signing & Capabilities" tab
   - Click "+ Capability" → Add "App Groups"
   - Add the **same** group: `group.clix.so.clix.samples.basic`

### 4. Configure Development Team

1. Open `BasicApp.xcodeproj` in Xcode
2. Select the project in the navigator
3. For both targets (BasicApp and ClixNotificationExtension):
   - Go to "Signing & Capabilities" tab
   - Select your development team

### 5. Build and Run

```bash
# Open in Xcode
open BasicApp.xcworkspace

# Or build from command line
xcodebuild -workspace BasicApp.xcworkspace -scheme BasicApp -configuration Debug
```

## Project Structure

```
BasicApp/
├── Sources/
│   ├── AppDelegate.swift           # Main app delegate with Clix integration
│   ├── BasicApp.swift             # App entry point
│   ├── ContentView.swift          # Main UI view
│   ├── AppState.swift            # App state management
│   ├── AppTheme.swift            # UI theming
│   └── ClixConfiguration.swift    # Clix SDK configuration loader
├── Resources/
│   ├── Assets.xcassets           # App assets
│   ├── LaunchScreen.storyboard   # Launch screen
│   ├── GoogleService-Info.plist  # Firebase config (not tracked in git)
│   └── ClixConfig.json           # Clix config (not tracked in git)
├── ClixNotificationExtension/
│   └── NotificationService.swift # Rich notification handler
├── BasicApp.xcodeproj
├── BasicApp.xcworkspace
├── ClixConfig.json.example       # Template for Clix configuration
└── README.md                     # This file
```

## Key Implementation Details

### AppDelegate Integration

The app uses `ClixAppDelegate` for automatic push notification setup:

```swift
class AppDelegate: ClixAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase BEFORE calling super
    FirebaseApp.configure()

    // Initialize Clix SDK with config loaded from JSON
    Clix.initialize(config: ClixConfiguration.config)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Configuration Loading

Configuration is loaded from `ClixConfig.json` at runtime and provides a ready-to-use `ClixConfig` instance:

```swift
enum ClixConfiguration {
  static let config: ClixConfig = {
    guard let url = Bundle.main.url(forResource: "ClixConfig", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      fatalError("Failed to load ClixConfig.json")
    }

    guard let projectId = json["projectId"] as? String,
          let apiKey = json["apiKey"] as? String,
          let endpoint = json["endpoint"] as? String else {
      fatalError("ClixConfig.json is missing required fields")
    }

    let extraHeaders = json["extraHeaders"] as? [String: String] ?? [:]

    return ClixConfig(
      projectId: projectId,
      apiKey: apiKey,
      endpoint: endpoint,
      logLevel: .debug,
      extraHeaders: extraHeaders
    )
  }()
}
```

**Usage**: Simply pass `ClixConfiguration.config` to `Clix.initialize()` - the configuration is loaded once and cached automatically.

### Rich Notification Extension

The Notification Service Extension handles rich push notifications with images:

```swift
class NotificationService: ClixNotificationServiceExtension {
  override init() {
    super.init()
    register(projectId: ClixConfiguration.config.projectId)
  }
}
```

## Testing Push Notifications

1. **Run on a physical device** (Push notifications don't work on iOS 26 simulator)
2. Allow notifications when prompted
3. Send a test notification from Firebase Console or Clix dashboard
4. Check device logs for SDK initialization and notification handling

## Troubleshooting

### App crashes on launch with "Failed to load ClixConfig.json"

- Ensure `ClixConfig.json` exists in `Resources/` directory
- Verify the JSON is valid and contains all required fields
- Check that the file is included in the app bundle (should be automatic with File System Synchronized Groups)

### Firebase token not collected

- Verify `GoogleService-Info.plist` is in `Resources/` directory
- Ensure `FirebaseApp.configure()` is called BEFORE `super.application()` in AppDelegate
- Check that APNs is properly configured in Firebase Console

### Notifications not appearing

- Verify App Groups are configured correctly in both targets
- Check that notification permissions are granted
- Ensure device is registered in Clix dashboard
- Review device logs for errors

### Rich notifications (images) not loading

- Verify Notification Service Extension has the same App Group configuration
- Check that `ClixConfiguration.projectId` is accessible in the extension
- Review extension logs in Console app

## Additional Resources

- [Clix iOS SDK Documentation](../../README.md)
- [Firebase Cloud Messaging Setup](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [App Groups Documentation](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)

## License

See the main SDK [LICENSE](../../LICENSE) file for details.
