import Clix
import Firebase
import UIKit
import UserNotifications

class AppDelegate: ClixAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()
    Task {
      do {
        // initialize
        try await Clix.initialize(config: ClixConfig(projectId: "", apiKey: ""))
        print("✅ Clix SDK initialized")
        AppState.shared.isClixInitialized = true
        // --- save user_id from UserDefaults to Clix ---
        if let savedUserId = UserDefaults.standard.string(forKey: "user_id"), !savedUserId.isEmpty {
          try? await Clix.setUserId(savedUserId)
          print("✅ Set user_id from UserDefaults: \(savedUserId)")
        }
      } catch {
        print("❌ Clix SDK failed to initialize:", error)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
