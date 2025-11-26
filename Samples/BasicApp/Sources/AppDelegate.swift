import Clix
import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications

class AppDelegate: ClixAppDelegate {
  override var autoRequestPermission: Bool { true }
  override var autoHandleLandingURL: Bool { true }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()
    Clix.initialize(config: ClixConfiguration.shared.config)
    updateClixValues()

    if let savedUserId = UserDefaults.standard.string(forKey: "user_id"), !savedUserId.isEmpty {
      Clix.setUserId(savedUserId)
      print("✅ Set user_id from UserDefaults: \(savedUserId)")
    }

    NotificationCenter.default.addObserver(
      forName: .MessagingRegistrationTokenRefreshed,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.updateClixValues()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Call parent implementation first to handle token processing
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)

    Messaging.messaging().token { token, error in
      if let error = error {
        print("❌ Error fetching FCM registration token after APNS registration: \(error)")
        return
      }

      if let token = token {
        print("✅ FCM registration token fetched after APNS registration: \(token)")
      }
    }

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
      let fcmToken = await Clix.Notification.getToken()

      AppState.shared.updateDeviceId(deviceId)
      AppState.shared.updateFCMToken(fcmToken)

      print("🔄 Updated AppState - Device ID: \(deviceId ?? "nil"), FCM Token: \(fcmToken ?? "nil")")
    }
  }
}
