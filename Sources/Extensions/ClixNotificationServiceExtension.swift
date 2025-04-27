import Foundation
import UserNotifications

public class ClixNotificationServiceExtension: UNNotificationServiceExtension {
  private var contentHandler: ((UNNotificationContent) -> Void)?
  private var bestAttemptContent: UNMutableNotificationContent?

  override public func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

    if let bestAttemptContent = bestAttemptContent {
      // Parse the notification payload and update the content
      guard let userInfo = bestAttemptContent.userInfo as? [String: Any],
        let clixInfo = userInfo["clix"] as? [String: Any]
      else {
        // No Clix-specific data, return original content
        contentHandler(bestAttemptContent)
        return
      }

      if let title = clixInfo["title"] as? String {
        bestAttemptContent.title = title
      }

      if let body = clixInfo["body"] as? String {
        bestAttemptContent.body = body
      }

      if let badge = clixInfo["badge"] as? NSNumber {
        bestAttemptContent.badge = badge
      }

      if let sound = clixInfo["sound"] as? String {
        bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(sound))
      }

      if let mediaUrl = request.content.userInfo["media_url"] as? String, let url = URL(string: mediaUrl) {
        Task {
          do {
            let attachment = try await downloadAndAttachMedia(
              url: url,
              type: request.content.userInfo["media_type"] as? String ?? "image"
            )
            bestAttemptContent.attachments = [attachment]
            contentHandler(bestAttemptContent)
          } catch {
            logError(error)
            contentHandler(bestAttemptContent)
          }
        }
      } else {
        contentHandler(bestAttemptContent)
      }
    }
  }

  private func downloadAndAttachMedia(url: URL, type: String) async throws -> UNNotificationAttachment {
    let downloadedFileURL = try await NetworkService.shared.downloadMedia(url: url)

    let attachment = try UNNotificationAttachment(
      identifier: UUID().uuidString,
      url: downloadedFileURL,
      options: nil  // Optionally add [UNNotificationAttachmentOptionsTypeHintKey: type]
    )
    return attachment
  }

  override public func serviceExtensionTimeWillExpire() {
    if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }
}

extension ClixNotificationServiceExtension {
  private func decryptContent(encrypted: String, withKey key: String) -> String? {
    // Implement decryption if needed
    // This is a placeholder for actual decryption logic
    nil
  }

  private func logError(_ error: Error) {
    ClixLogger.shared.log(
      level: .error,
      category: .pushNotification,
      message: error.localizedDescription,
      error: error
    )
  }

  private func logInfo(_ message: String) {
    ClixLogger.shared.log(
      level: .info,
      category: .pushNotification,
      message: message
    )
  }
}
