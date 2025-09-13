import UserNotifications
import Foundation

/**
 * ClixNotificationServiceExtension
 *
 * A notification service extension that extends UNNotificationServiceExtension to handle
 * rich push notifications with enhanced features such as image processing and analytics tracking.
 *
 * This class provides the following key functionalities:
 * - Registration with Clix project ID for notification services
 * - Processing of incoming push notifications with user interaction tracking
 * - Rich media content handling (images, videos) in push notifications
 * - Automatic fallback handling when service extension time expires
 *
 * Usage:
 * 1. Create a Notification Service Extension target in your iOS app
 * 2. Subclass ClixNotificationServiceExtension in your NotificationService class
 * 3. Call register(projectId:) during initialization with your Clix project ID
 * 4. The extension will automatically handle incoming notifications and process rich content
 *
 * Example:
 * ```swift
 * class NotificationService: ClixNotificationServiceExtension {
 *     override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
 *         register(projectId: "your-project-id")
 *         super.didReceive(request, withContentHandler: contentHandler)
 *     }
 * }
 * ```
 *
 * Note: This class requires iOS 14+ and Swift 5.5+ compatibility.
 * Ensure that the main Clix SDK is properly initialized before using this extension.
 */
open class ClixNotificationServiceExtension: UNNotificationServiceExtension {
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  open func register(projectId: String) {
    Task {
      try await Clix.initialize(projectId: projectId)
      ClixLogger.info("Registered with project ID: \(projectId)")
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

    Task {
      do {
        let notificationService = try await Clix.shared.getWithWait(\.notificationService)
        notificationService.handlePushReceived(userInfo: bestAttemptContent.userInfo)
        notificationService.processNotificationWithImage(
          content: bestAttemptContent,
          completion: contentHandler
        )
      } catch {
        ClixLogger.error("NotificationService not initialized: \(error)")
        contentHandler(bestAttemptContent)
      }
    }
  }

  open override func serviceExtensionTimeWillExpire() {
    if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }
}
