import Foundation
import UserNotifications
import UIKit

/// Notification settings model
private struct NotificationSettings: Codable {
  var enabled: Bool
  var categories: [String]?
  var lastUpdated: Date
}

actor NotificationService {
  private let eventAPIService = EventAPIService()
  private let storageService: StorageService
  private let settingsKey = "clix_notification_settings"
  private let lastNotificationKey = "clix_last_notification"

  init(storageService: StorageService) {
    self.storageService = storageService
  }

  func handleNotificationReceived(_ payload: [AnyHashable: Any]) async throws {
    guard let deviceId = await Clix.shared.getEnvironment()?.deviceId else { return }
    let properties: [String: AnyCodable] = ["payload": AnyCodable(payload)]
    try await eventAPIService.trackEvent(deviceId: deviceId, name: "push_received", properties: properties)
  }

  func handleNotificationResponse(_ response: UNNotificationResponse) async throws {
    guard let deviceId = await Clix.shared.getEnvironment()?.deviceId else { return }
    let properties: [String: AnyCodable] = ["payload": AnyCodable(response.notification.request.content.userInfo)]
    try await eventAPIService.trackEvent(deviceId: deviceId, name: "push_opened", properties: properties)
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

    // Save notification settings
    let settings = NotificationSettings(
      enabled: enabled,
      categories: categories,
      lastUpdated: Date()
    )
    await storageService.set(settings, forKey: settingsKey)

    // TODO: Register categories if needed
  }

  /// Get current notification settings
  /// - Returns: Current notification settings if exists
  private func getNotificationSettings() async -> NotificationSettings? {
    await storageService.get(forKey: settingsKey)
  }

  func requestNotificationPermission() async throws {
    let granted = try await UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .sound, .badge])
    if granted {
      await MainActor.run {
        UIApplication.shared.registerForRemoteNotifications()
      }
    }

    // Save the permission status
    let settings = NotificationSettings(
      enabled: granted,
      categories: nil,
      lastUpdated: Date()
    )
    await storageService.set(settings, forKey: settingsKey)
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
