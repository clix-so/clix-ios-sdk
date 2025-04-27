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
          if let attachment = try? await downloadAndAttachMedia(
            url: url,
            type: request.content.userInfo["media_type"] as? String ?? "image"
          ) {
            bestAttemptContent.attachments = [attachment]
          }
          contentHandler(bestAttemptContent)
        }
      } else {
        contentHandler(bestAttemptContent)
      }
    }
  }

  private func downloadAndAttachMedia(url: URL, type: String) async throws -> UNNotificationAttachment {
    try await withCheckedThrowingContinuation { continuation in
      let task = URLSession.shared.downloadTask(with: url) { temporaryFileLocation, response, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }

        guard let temporaryFileLocation = temporaryFileLocation,
          let response = response as? HTTPURLResponse,
          (200...299).contains(response.statusCode)
        else {
          continuation.resume(
            throwing: NSError(
              domain: "ClixNotificationService",
              code: -1,
              userInfo: [NSLocalizedDescriptionKey: "Invalid response"]
            )
          )
          return
        }

        let fileManager = FileManager.default
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let uniqueFilename = "\(UUID().uuidString).\(type)"
        let destinationURL = temporaryDirectory.appendingPathComponent(uniqueFilename)

        do {
          if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
          }
          try fileManager.moveItem(at: temporaryFileLocation, to: destinationURL)

          let attachment = try UNNotificationAttachment(
            identifier: UUID().uuidString,
            url: destinationURL,
            options: nil
          )
          continuation.resume(returning: attachment)
        } catch {
          continuation.resume(throwing: error)
        }
      }
      task.resume()
    }
  }

  override public func serviceExtensionTimeWillExpire() {
    if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }
}

// Helper functions for notification processing
extension ClixNotificationServiceExtension {
  private func decryptContent(encrypted: String, withKey key: String) -> String? {
    // Implement decryption if needed
    // This is a placeholder for actual decryption logic
    nil
  }

  private func logError(_ error: Error) {
    NSLog("[ClixNotificationService] [ERROR] %@", error.localizedDescription)
  }

  private func logInfo(_ message: String) {
    NSLog("[ClixNotificationService] [INFO] %@", message)
  }
}
