import Foundation
import UserNotifications

class NotificationService {
  private let networkService: NetworkService

  init(networkService: NetworkService = NetworkService.shared) {
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

  /// Sets notification preferences
  /// - Parameters:
  ///   - enabled: Whether notifications are enabled
  ///   - categories: Notification categories to register for
  func setNotificationPreferences(enabled: Bool, categories: [String]? = nil) async throws {
    let center = UNUserNotificationCenter.current()
    if enabled {
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      let granted = try await center.requestAuthorization(options: authOptions)
      if !granted {
        throw ClixError.invalidResponse
      }
    }
    
    // TODO: Register categories if needed
  }

  /// Resets notification state
  func reset() {
    UserDefaults.standard.removeObject(forKey: "clix_notification_settings")
    UserDefaults.standard.removeObject(forKey: "clix_last_notification")
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
  }
}
