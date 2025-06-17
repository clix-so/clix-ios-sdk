import Clix
import UserNotifications

/// NotificationService now inherits all logic from ClixNotificationServiceExtension
/// No additional logic is needed unless you want to customize notification handling.
class NotificationService: ClixNotificationServiceExtension {
  override init() {
    super.init()
    register(projectId: ClixConfiguration.projectId)

    NSLog("[NotificationService] Notification service initialized")
  }

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    NSLog("[NotificationService] Received notification request")
    super.didReceive(request, withContentHandler: contentHandler)
  }

  override func serviceExtensionTimeWillExpire() {
    NSLog("[NotificationService] Service extension time will expire")
    super.serviceExtensionTimeWillExpire()
  }
}
