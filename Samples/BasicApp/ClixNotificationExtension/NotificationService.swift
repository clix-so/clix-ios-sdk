//
//  NotificationService.swift
//  ClixNotificationExtension
//
//  Created by Jeongwoo Yoo on 5/28/25.
//

import Clix  // Or the actual module name where ClixNotificationServiceExtension is defined
import UserNotifications

/// NotificationService now inherits all logic from ClixNotificationServiceExtension
/// No additional logic is needed unless you want to customize notification handling.
class NotificationService: ClixNotificationServiceExtension {
  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    super.didReceive(request, withContentHandler: contentHandler)
  }

  override func serviceExtensionTimeWillExpire() {
    super.serviceExtensionTimeWillExpire()
  }
}
