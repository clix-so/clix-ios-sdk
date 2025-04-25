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
