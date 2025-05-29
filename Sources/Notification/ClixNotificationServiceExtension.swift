import UserNotifications
import Foundation

/// A reusable notification service extension for displaying images in push notifications and tracking notification events.
/// Also sends push received events to the Clix server using shared UserDefaults configuration.

/// A reusable notification service extension for displaying images in push notifications.
/// Subclass or use directly in your Notification Service Extension target.
open class ClixNotificationServiceExtension: UNNotificationServiceExtension {

  open var contentHandler: ((UNNotificationContent) -> Void)?
  open var bestAttemptContent: UNMutableNotificationContent?

  private let notificationService = ExtensionNotificationService()
  
  /// Project ID for the Clix service
  private var projectId: String?
  
  /// Register the project ID for this extension
  /// Call this method in your subclass's init method
  /// - Parameter projectId: The Clix project ID
  open func register(projectId: String) {
    self.projectId = projectId
    
    // Generate app group ID based on project ID
    let appGroupId = ClixUserDefault.getAppGroupId(projectId: projectId)
    
    // Configure UserDefaults with the app group ID
    NSLog("[ClixNotificationServiceExtension] Registering with project ID: \(projectId), app group ID: \(appGroupId)")
    ClixUserDefault.shared.configure(appGroupId: appGroupId)
  }
  
  /// Gets the app group ID based on project ID from UserDefaults
  /// - Returns: App group ID in the format "group.clix.{project_id}"
  private func getAppGroupIdFromProjectId() -> String {
    // Try to get project ID from UserDefaults first
    let projectId = ClixUserDefault.shared.getProjectId()
    
    if !projectId.isEmpty {
      return ClixUserDefault.getAppGroupId(projectId: projectId)
    } else {
      // Fallback to a generic app group ID if project ID is not available
      NSLog("[ClixNotificationServiceExtension] WARNING: Project ID not found in UserDefaults, using fallback app group ID")
      return "group.clix.fallback"
    }
  }

  open override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

    guard let bestAttemptContent = bestAttemptContent else {
      contentHandler(request.content)
      return
    }
    
    // Check if project ID is registered
    if projectId == nil {
      NSLog("[ClixNotificationServiceExtension] WARNING: Project ID not registered. Call register(projectId:) before using this extension.")
      
      // Try to use the fallback method to get app group ID
      let appGroupId = getAppGroupIdFromProjectId()
      NSLog("[ClixNotificationServiceExtension] Using fallback app group ID: \(appGroupId)")
      ClixUserDefault.shared.configure(appGroupId: appGroupId)
    }

    // Send push received event to Clix server
    Task {
      await notificationService.handlePushReceived(userInfo: bestAttemptContent.userInfo)
    }

    // Extract image URL from all supported payload formats
    var imageURLString: String? = nil

    NSLog("[ClixNotificationServiceExtension] Processing notification with payload: \(bestAttemptContent.userInfo)")

    // Try to get image_url from Clix payload first
    if let clixData = parseClixPayload(from: bestAttemptContent.userInfo),
      let imageURL = clixData["image_url"] as? String
    {
      imageURLString = imageURL
      NSLog("[ClixNotificationServiceExtension] Found image_url in Clix payload: \(imageURL)")
    }

    // Fallback to traditional methods if not found in Clix payload
    if imageURLString == nil {
      if let directImage = bestAttemptContent.userInfo["image"] as? String {
        imageURLString = directImage
        NSLog("[ClixNotificationServiceExtension] Found image in userInfo: \(directImage)")
      } else if let directImageUrl = bestAttemptContent.userInfo["image_url"] as? String {
        imageURLString = directImageUrl
        NSLog("[ClixNotificationServiceExtension] Found image_url in userInfo: \(directImageUrl)")
      } else if let fcmOptions = bestAttemptContent.userInfo["fcm_options"] as? [String: Any] {
        if let image = fcmOptions["image"] as? String {
          imageURLString = image
          NSLog("[ClixNotificationServiceExtension] Found image in fcm_options: \(image)")
        } else if let imageUrl = fcmOptions["image_url"] as? String {
          imageURLString = imageUrl
          NSLog("[ClixNotificationServiceExtension] Found image_url in fcm_options: \(imageUrl)")
        }
      } else if let fcmOptions = bestAttemptContent.userInfo["fcm_options"] as? NSDictionary {
        if let image = fcmOptions["image"] as? String {
          imageURLString = image
          NSLog("[ClixNotificationServiceExtension] Found image in fcm_options dictionary: \(image)")
        } else if let imageUrl = fcmOptions["image_url"] as? String {
          imageURLString = imageUrl
          NSLog("[ClixNotificationServiceExtension] Found image_url in fcm_options dictionary: \(imageUrl)")
        }
      }
    }

    if imageURLString == nil {
      NSLog("[ClixNotificationServiceExtension] No image URL found in notification payload")
    }

    if let imageURLString = imageURLString {
      guard let fileURL = URL(string: imageURLString) else {
        NSLog("[ClixNotificationServiceExtension] Invalid image URL: \(imageURLString)")
        contentHandler(bestAttemptContent)
        return
      }

      NSLog("[ClixNotificationServiceExtension] Attempting to download image from: \(fileURL)")
      downloadImage(from: fileURL) { attachment in
        if let attachment = attachment {
          NSLog("[ClixNotificationServiceExtension] Successfully created attachment from image")
          bestAttemptContent.attachments = [attachment]
        } else {
          NSLog("[ClixNotificationServiceExtension] Failed to create attachment from downloaded image")
        }
        contentHandler(bestAttemptContent)
      }
    } else {
      NSLog("[ClixNotificationServiceExtension] No image URL found, delivering notification without image")
      contentHandler(bestAttemptContent)
    }
  }

  open override func serviceExtensionTimeWillExpire() {
    // Called just before the extension will be terminated by the system.
    if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }

  /// Helper method to parse the Clix payload from push notification userInfo
  /// - Parameter userInfo: The notification's userInfo dictionary
  /// - Returns: Parsed Clix payload as [String: Any], or nil if parsing fails
  private func parseClixPayload(from userInfo: [AnyHashable: Any]) -> [String: Any]? {
    guard let clixValue = userInfo["clix"] else { return nil }

    // 1. Try parsing as a dictionary directly
    if let clixData = clixValue as? [String: Any] {
      return clixData
    }
    // 2. Try parsing as a JSON string
    if let clixString = clixValue as? String {
      do {
        if let data = clixString.data(using: .utf8),
          let clixData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
          return clixData
        }
      } catch {
        // Unable to parse JSON
      }
    }
    return nil
  }

  /// Downloads an image and returns a UNNotificationAttachment if successful
  open func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
    let session = URLSession(configuration: .default)
    let task = session.downloadTask(with: url) { (downloadedUrl, response, error) in
      if let error = error {
        NSLog("[ClixNotificationServiceExtension] Error downloading image: \(error.localizedDescription)")
        completion(nil)
        return
      }

      guard let downloadedUrl = downloadedUrl else {
        NSLog("[ClixNotificationServiceExtension] Downloaded URL is nil")
        completion(nil)
        return
      }

      guard let httpResponse = response as? HTTPURLResponse else {
        NSLog("[ClixNotificationServiceExtension] Invalid response type")
        completion(nil)
        return
      }

      if httpResponse.statusCode != 200 {
        NSLog("[ClixNotificationServiceExtension] HTTP error: \(httpResponse.statusCode)")
        completion(nil)
        return
      }

      let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
      let fileName = url.lastPathComponent.isEmpty ? "image-\(UUID().uuidString)" : url.lastPathComponent
      let tmpFile = tmpDir.appendingPathComponent(fileName)

      // Remove existing file if it exists
      if FileManager.default.fileExists(atPath: tmpFile.path) {
        do {
          try FileManager.default.removeItem(at: tmpFile)
          NSLog("[ClixNotificationServiceExtension] Removed existing file at: \(tmpFile.path)")
        } catch {
          NSLog("[ClixNotificationServiceExtension] Error removing existing file: \(error.localizedDescription)")
        }
      }

      do {
        try FileManager.default.moveItem(at: downloadedUrl, to: tmpFile)
        NSLog("[ClixNotificationServiceExtension] Image saved to: \(tmpFile.path)")

        let attachment = try UNNotificationAttachment(identifier: "image", url: tmpFile, options: nil)
        NSLog("[ClixNotificationServiceExtension] Attachment created successfully")
        completion(attachment)
      } catch {
        print("[ClixNotificationServiceExtension] Error creating attachment: \(error.localizedDescription)")
        completion(nil)
      }
    }

    // Set a timeout for the download
    task.resume()
  }
}
