import Clix
import Firebase
import FirebaseMessaging
import UIKit
import UserNotifications

class AppDelegate: ClixAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()
    Clix.initialize(
      config: ClixConfig(
        projectId: ClixConfiguration.projectId,
        apiKey: ClixConfiguration.apiKey,
        logLevel: .debug
      )
    )
    AppState.shared.isClixInitialized = true
    updateClixValues()

    if let savedUserId = UserDefaults.standard.string(forKey: "user_id"), !savedUserId.isEmpty {
      Clix.setUserId(savedUserId)
      print("✅ Set user_id from UserDefaults: \(savedUserId)")
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Call parent implementation first to handle token processing
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)

    // Update values after APNS token is processed
    print("🔄 APNS Token received and processed")
    updateClixValues()
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    print("❌ Failed to register for remote notifications: \(error)")
  }


  private func updateClixValues() {
    Task {
      let deviceId = await Clix.getDeviceId()
      let fcmToken = await Clix.getPushToken()

      AppState.shared.updateDeviceId(deviceId)
      AppState.shared.updateFCMToken(fcmToken)

      print("🔄 Updated AppState - Device ID: \(deviceId ?? "nil"), FCM Token: \(fcmToken ?? "nil")")
    }
  }
}
