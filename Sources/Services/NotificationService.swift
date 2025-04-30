import Foundation
import UserNotifications
import UIKit
class NotificationService {
  private let eventAPIService: EventAPIService
  private let storageService: StorageService
  private let settingsKey = "clix_notification_settings"
  private let lastNotificationKey = "clix_last_notification"

  init(eventAPI: EventAPIService = EventAPIService(), storageService: StorageService = StorageService()) {
    self.eventAPIService = eventAPI
    self.storageService = storageService
  }

  func handleNotificationReceived(_ userInfo: [AnyHashable: Any]) async throws {
    try await eventAPIService.trackEvent(
      name: "push_received",
      properties: ["payload": userInfo],
      userId: nil
    )
  }

  func handleNotificationResponse(_ response: UNNotificationResponse) async throws {
    try await eventAPIService.trackEvent(
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

  func requestNotificationPermission() async throws {
    let granted = try await UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .sound, .badge])
    if granted {
      await MainActor.run {
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }

  /// Resets notification state
  func reset() {
    UserDefaults.standard.removeObject(forKey: "clix_notification_settings")
    UserDefaults.standard.removeObject(forKey: "clix_last_notification")
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
  }
}
