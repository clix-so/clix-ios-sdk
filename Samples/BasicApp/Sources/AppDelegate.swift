import UIKit
import UserNotifications
import Clix
import Firebase

class AppDelegate: ClixAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()
    Task {
      do {
        try await Clix.initialize(
          config: ClixConfig(
            apiKey: "",
            projectId: ""
          )
        )
        print("✅ Clix SDK initialized")
      } catch {
        print("❌ Clix SDK failed to initialize:", error)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
