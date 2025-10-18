import Foundation
import UserNotifications
import UIKit

private struct NotificationSettings: Codable {
  var enabled: Bool
  var categories: [String]?
  var lastUpdated: Date
}

enum NotificationEvent: String {
  case pushNotificationReceived = "PUSH_NOTIFICATION_RECEIVED"
  case pushNotificationTapped = "PUSH_NOTIFICATION_TAPPED"
}

class NotificationService {
  private let eventService: EventService
  private let storageService: StorageService
  private let settingsKey = "clix_notification_settings"
  private let lastReceivedMessageIdKey = "clix_last_received_message_id"

  init(storageService: StorageService, eventService: EventService) {
    self.storageService = storageService
    self.eventService = eventService
  }

  func handlePushReceived(userInfo: [AnyHashable: Any]) {
    if let messageId = getMessageId(userInfo: userInfo) {
      let userJourneyId = getUserJourneyId(userInfo: userInfo)
      let userJourneyNodeId = getUserJourneyNodeId(userInfo: userInfo)

      Task {
        let shouldTrack = await recordReceivedMessageId(messageId: messageId)
        guard shouldTrack else {
          ClixLogger.debug("Skipping duplicate \(NotificationEvent.pushNotificationReceived.rawValue) for messageId: \(messageId)")
          return
        }

        do {
          try await eventService.trackEvent(
            name: NotificationEvent.pushNotificationReceived.rawValue,
            messageId: messageId,
            userJourneyId: userJourneyId,
            userJourneyNodeId: userJourneyNodeId
          )
        } catch {
          await recoverReceivedMessageId(messageId: messageId)
          ClixLogger.error("Failed to track \(NotificationEvent.pushNotificationReceived.rawValue)", error: error)
        }
      }
    } else {
      ClixLogger.warn("messageId not found in userInfo")
    }
  }

  func handlePushTapped(userInfo: [AnyHashable: Any]) {
    if let messageId = getMessageId(userInfo: userInfo) {
      let userJourneyId = getUserJourneyId(userInfo: userInfo)
      let userJourneyNodeId = getUserJourneyNodeId(userInfo: userInfo)

      Task {
        do {
          try await eventService.trackEvent(
            name: NotificationEvent.pushNotificationTapped.rawValue,
            messageId: messageId,
            userJourneyId: userJourneyId,
            userJourneyNodeId: userJourneyNodeId
          )
        } catch {
          ClixLogger.error("Failed to track \(NotificationEvent.pushNotificationTapped.rawValue)", error: error)
        }
      }
    } else {
      ClixLogger.warn("messageId not found in userInfo")
    }
  }

  private func getMessageId(userInfo: [AnyHashable: Any]) -> String? {
    if let clixData = parseClixPayload(from: userInfo),
      let messageId = clixData["message_id"] as? String
    {
      return messageId
    }

    return nil
  }

  private func getUserJourneyId(userInfo: [AnyHashable: Any]) -> String? {
    if let clixData = parseClixPayload(from: userInfo),
      let userJourneyId = clixData["user_journey_id"] as? String
    {
      return userJourneyId
    }

    return nil
  }

  private func getUserJourneyNodeId(userInfo: [AnyHashable: Any]) -> String? {
    if let clixData = parseClixPayload(from: userInfo),
      let userJourneyNodeId = clixData["user_journey_node_id"] as? String
    {
      return userJourneyNodeId
    }

    return nil
  }

  func parseClixPayload(from userInfo: [AnyHashable: Any]) -> [String: Any]? {
    guard let clixValue = userInfo["clix"] else { return nil }

    if let clixData = clixValue as? [String: Any] {
      return clixData
    }

    if let clixString = clixValue as? String {
      do {
        if let data = clixString.data(using: .utf8),
          let clixData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
          return clixData
        }
      } catch {
        ClixLogger.warn("Error parsing Clix payload", error: error)
      }
    }
    return nil
  }

  func extractImageURL(from userInfo: [AnyHashable: Any]) -> String? {
    if let clixData = parseClixPayload(from: userInfo),
      let imageURL = clixData["image_url"] as? String
    {
      ClixLogger.info("Found image_url in Clix payload: \(imageURL)")
      return imageURL
    }

    return extractImageURLFromTraditionalSources(userInfo: userInfo)
  }

  private func extractImageURLFromTraditionalSources(userInfo: [AnyHashable: Any]) -> String? {
    if let directImage = userInfo["image"] as? String {
      ClixLogger.info("Found image in userInfo: \(directImage)")
      return directImage
    }

    if let directImageUrl = userInfo["image_url"] as? String {
      ClixLogger.info("Found image_url in userInfo: \(directImageUrl)")
      return directImageUrl
    }

    if let fcmOptions = userInfo["fcm_options"] as? [String: Any] {
      return extractImageFromFCMOptions(fcmOptions)
    }

    if let fcmOptions = userInfo["fcm_options"] as? NSDictionary {
      return extractImageFromFCMDictionary(fcmOptions)
    }

    ClixLogger.debug("No image URL found in notification payload")
    return nil
  }

  private func extractImageFromFCMOptions(_ fcmOptions: [String: Any]) -> String? {
    if let image = fcmOptions["image"] as? String {
      ClixLogger.info("Found image in fcm_options: \(image)")
      return image
    }

    if let imageUrl = fcmOptions["image_url"] as? String {
      ClixLogger.info("Found image_url in fcm_options: \(imageUrl)")
      return imageUrl
    }

    return nil
  }

  private func extractImageFromFCMDictionary(_ fcmOptions: NSDictionary) -> String? {
    if let image = fcmOptions["image"] as? String {
      ClixLogger.info("Found image in fcm_options dictionary: \(image)")
      return image
    }

    if let imageUrl = fcmOptions["image_url"] as? String {
      ClixLogger.info("Found image_url in fcm_options dictionary: \(imageUrl)")
      return imageUrl
    }

    return nil
  }

  func downloadNotificationImage(from url: URL) async -> UNNotificationAttachment? {
    do {
      let downloadedFile = try await HTTPClient.shared.download(url)
      ClixLogger.debug("Image saved to: \(downloadedFile.path)")
      let attachment = try UNNotificationAttachment(identifier: "image", url: downloadedFile, options: nil)
      ClixLogger.debug("Attachment created successfully")
      return attachment
    } catch {
      ClixLogger.error("Error downloading or creating attachment", error: error)
      return nil
    }
  }

  func downloadNotificationImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
    Task {
      let attachment = await downloadNotificationImage(from: url)
      completion(attachment)
    }
  }

  func processNotificationWithImage(content: UNMutableNotificationContent) async -> UNNotificationContent {
    ClixLogger.debug("Processing notification with payload: \(content.userInfo)")

    let imageURLString = extractImageURL(from: content.userInfo)

    if let imageURLString = imageURLString, let fileURL = URL(string: imageURLString) {
      ClixLogger.info("Attempting to download image from: \(fileURL)")
      if let attachment = await downloadNotificationImage(from: fileURL) {
        ClixLogger.info("Successfully created attachment from image")
        content.attachments = [attachment]
      } else {
        ClixLogger.warn("Failed to create attachment from downloaded image")
      }
    } else {
      ClixLogger.debug("No image URL found, delivering notification without image")
    }

    return content
  }

  func processNotificationWithImage(
    content: UNMutableNotificationContent,
    completion: @escaping (UNNotificationContent) -> Void
  ) {
    Task {
      let updatedContent = await processNotificationWithImage(content: content)
      completion(updatedContent)
    }
  }

  func setNotificationPreferences(enabled: Bool, categories: [String]? = nil) async throws {
    let center = UNUserNotificationCenter.current()
    if enabled {
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      let granted = try await center.requestAuthorization(options: authOptions)
      if !granted {
        throw ClixError.invalidResponse
      }
    }

    let settings = NotificationSettings(
      enabled: enabled,
      categories: categories,
      lastUpdated: Date()
    )
    await storageService.set(settingsKey, settings)
  }

  private func getNotificationSettings() async -> NotificationSettings? {
    await storageService.get(settingsKey)
  }

  func requestNotificationPermission() async throws {
    ClixLogger.debug("Requesting notification permission")
    let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    ClixLogger.debug("Notification permission \(granted ? "granted": "denied")")

    let settings = NotificationSettings(
      enabled: granted,
      categories: nil,
      lastUpdated: Date()
    )
    await storageService.set(settingsKey, settings)
    let deviceService = try await Clix.shared.getWithWait(\.deviceService)
    try await deviceService.upsertIsPushPermissionGranted(granted)
    ClixLogger.debug("Push permission synced to server")
  }

  private func recordReceivedMessageId(messageId: String) async -> Bool {
    let previous: String? = await storageService.get(lastReceivedMessageIdKey)
    if previous == messageId { return false }
    await storageService.set(lastReceivedMessageIdKey, messageId)
    return true
  }

  private func recoverReceivedMessageId(messageId: String) async {
    let previous: String? = await storageService.get(lastReceivedMessageIdKey)
    if previous == messageId {
      await storageService.remove(lastReceivedMessageIdKey)
    }
  }

  func reset() async {
    await storageService.remove(settingsKey)
    await storageService.remove(lastReceivedMessageIdKey)

    await MainActor.run {
      UNUserNotificationCenter.current().removeAllDeliveredNotifications()
      UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
  }

}
