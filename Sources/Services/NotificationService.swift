import Foundation
import UserNotifications
import UIKit

actor NotificationService {
  private let eventAPIService = EventAPIService()
  private let storageService = StorageService()
  private let settingsKey = "clix_notification_settings"
  private let lastNotificationKey = "clix_last_notification"

  func handleNotificationReceived(_ payload: [AnyHashable: Any]) async throws {
    try await eventAPIService.trackEvent(
      name: "push_received",
      properties: ["payload": payload]
    )
  }

  func handleNotificationResponse(_ response: UNNotificationResponse) async throws {
    try await eventAPIService.trackEvent(
      name: "push_opened",
      properties: ["payload": response.notification.request.content.userInfo]
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
  func reset() async {
    await storageService.remove(forKey: settingsKey)
    await storageService.remove(forKey: lastNotificationKey)

    await MainActor.run {
      UNUserNotificationCenter.current().removeAllDeliveredNotifications()
      UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
  }
}
