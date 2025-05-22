import UIKit
import Clix
import FirebaseCore
import FirebaseMessaging

@main
class AppDelegate: ClixAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    Messaging.messaging().delegate = self

    Task {
      await Clix.setUserId("clix_user")
      await Clix.setProperties([
        "name": "Clix User",
        "age": 25,
        "premium": true,
      ])
    }

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    print("[SampleApp] App did finish launching")
    return result
  }

  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("[SampleApp] FCM registration token: \(fcmToken ?? "nil")")
  }

  override func pushNotificationDeliveredInForeground(notification: UNNotification)
    -> UNNotificationPresentationOptions {
    print("[SampleApp] Push received in foreground: \(notification.request.content.userInfo)")
    return [.banner, .sound, .badge]
  }

  override func pushNotificationTapped(userInfo: [AnyHashable: Any]) {
    print("[SampleApp] Push tapped: \(userInfo)")
    super.pushNotificationTapped(userInfo: userInfo)
  }
}

extension AppDelegate: MessagingDelegate {}
