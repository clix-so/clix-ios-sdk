//
//  NotificationService.swift
//  ClixNotificationExtension
//
//  Created by Jeongwoo Yoo on 5/28/25.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

    if let bestAttemptContent = bestAttemptContent {
      // Extract image URL from all supported payload formats
      var imageURLString: String? = nil
      if let directImage = bestAttemptContent.userInfo["image"] as? String {
        imageURLString = directImage
      } else if let fcmOptions = bestAttemptContent.userInfo["fcm_options"] as? [String: Any], let fcmImage = fcmOptions["image"] as? String {
        imageURLString = fcmImage
      } else if let fcmOptions = bestAttemptContent.userInfo["fcm_options"] as? NSDictionary, let fcmImage = fcmOptions["image"] as? String {
        imageURLString = fcmImage
      }
      if let imageURLString = imageURLString, let fileURL = URL(string: imageURLString) {
        downloadImage(from: fileURL) { attachment in
          if let attachment = attachment {
            bestAttemptContent.attachments = [attachment]
          }
          contentHandler(bestAttemptContent)
        }
      } else {
        contentHandler(bestAttemptContent)
      }
    }
  }

  override func serviceExtensionTimeWillExpire() {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }
  private func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
    let task = URLSession.shared.downloadTask(with: url) { (downloadedUrl, response, error) in
      guard let downloadedUrl = downloadedUrl else {
        completion(nil)
        return
      }
      let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
      let tmpFile = tmpDir.appendingPathComponent(url.lastPathComponent)
      try? FileManager.default.moveItem(at: downloadedUrl, to: tmpFile)
      let attachment = try? UNNotificationAttachment(identifier: "image", url: tmpFile, options: nil)
      completion(attachment)
    }
    task.resume()
  }
}
