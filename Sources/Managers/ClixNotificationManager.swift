import Foundation
import UserNotifications

class ClixNotificationManager {
  private let networkManager: ClixNetworkManager

  init(networkManager: ClixNetworkManager = ClixNetworkManager.shared) {
    self.networkManager = networkManager
  }

  func handleNotificationReceived(_ userInfo: [AnyHashable: Any]) async throws {
    try await networkManager.trackEvent(
      name: "push_received",
      properties: ["payload": userInfo],
      userId: nil
    )
  }

  func handleNotificationResponse(_ response: UNNotificationResponse) async throws {
    try await networkManager.trackEvent(
      name: "push_opened",
      properties: ["payload": response.notification.request.content.userInfo],
      userId: nil
    )
  }

  func reset() {
    UserDefaults.standard.removeObject(forKey: "clix_notification_settings")
    UserDefaults.standard.removeObject(forKey: "clix_last_notification")
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
  }
}
