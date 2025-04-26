import Foundation
import UserNotifications

class ClixNotificationService {
  private let networkService: ClixNetworkService

  init(networkService: ClixNetworkService = ClixNetworkService.shared) {
    self.networkService = networkService
  }

  func handleNotificationReceived(_ userInfo: [AnyHashable: Any]) async throws {
    try await networkService.trackEvent(
      name: "push_received",
      properties: ["payload": userInfo],
      userId: nil
    )
  }

  func handleNotificationResponse(_ response: UNNotificationResponse) async throws {
    try await networkService.trackEvent(
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
