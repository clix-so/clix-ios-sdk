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
  private let eventService = EventService()
  private let storageService: StorageService
  private let settingsKey = "clix_notification_settings"
  private let lastNotificationKey = "clix_last_notification"

  init(storageService: StorageService) {
    self.storageService = storageService
  }

  func handlePushReceived(userInfo: [AnyHashable: Any]) {
    Task {
      if let messageId = getMessageId(userInfo: userInfo) {
        do {
          try await eventService.trackEvent(name: "PUSH_NOTIFICATION_RECEIVED", messageId: messageId)
        } catch {
          ClixLogger.error("Failed to track PUSH_NOTIFICATION_RECEIVED", error: error)
        }
      } else {
        ClixLogger.warn("messageId not found in userInfo")
      }
    }
  }

  func handlePushTapped(userInfo: [AnyHashable: Any]) {
    Task {
      if let messageId = getMessageId(userInfo: userInfo) {
        do {
          try await eventService.trackEvent(name: "PUSH_NOTIFICATION_TAPPED", messageId: messageId)
        } catch {
          ClixLogger.error("Failed to track PUSH_NOTIFICATION_TAPPED", error: error)
        }
      } else {
        ClixLogger.warn("messageId not found in userInfo")
      }
    }
  }
    
  private func getMessageId(userInfo: [AnyHashable: Any]) -> String? {
    guard let clixJsonString = userInfo["clix"] as? String,
        let data = clixJsonString.data(using: .utf8) else {
      return nil
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    do {
      let payload = try decoder.decode(ClixPushNotificationPayload.self, from: data)
      return payload.messageId
    } catch {
      ClixLogger.error("Failed to decode ClixPushNotificationPayload", error: error)
      return nil
    }
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
