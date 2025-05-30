import Foundation

/// Service class to handle notification events in extensions
/// Uses ExtensionAPIClient to communicate with the server
class ExtensionNotificationService {
  private let apiClient = ExtensionAPIClient()

  /// Handle push notification received event
  /// Makes the same request as NotificationService.handlePushReceived
  func handlePushReceived(userInfo: [AnyHashable: Any]) async {
    guard let deviceId = await ClixUserDefault.shared.getDeviceId() as? String else {
      NSLog("[ClixNotificationServiceExtension] Failed to retrieve deviceId")
      return
    }
    NSLog("[ClixNotificationServiceExtension] Successfully retrieved deviceId: \(deviceId)")

    if let messageId = getMessageId(userInfo: userInfo) {
      do {
        let events = EventRequestBody(
          device_id: deviceId,
          name: "PUSH_NOTIFICATION_RECEIVED",
          event_property: ["custom_properties": AnyCodable([:]), "message_id": AnyCodable(messageId)]
        )

        // Use EmptyResponse as we don't need to parse the response
        let _: EmptyResponse = try await apiClient.post(path: "/events", data: ["events": [events]])
        NSLog("[ClixNotificationServiceExtension] Successfully tracked PUSH_NOTIFICATION_RECEIVED in extension")
      } catch {
        NSLog(
          "[ClixNotificationServiceExtension] Failed to track PUSH_NOTIFICATION_RECEIVED in extension: \(error.localizedDescription)"
        )
      }
    } else {
      NSLog("[ClixNotificationServiceExtension] messageId not found in userInfo for extension")
    }
  }

  /// Extract messageId from push notification payload
  private func getMessageId(userInfo: [AnyHashable: Any]) -> String? {
    // First try to get clix payload directly as a dictionary
    if let clixData = userInfo["clix"] as? [String: Any],
      let messageId = clixData["message_id"] as? String
    {
      return messageId
    }

    // Next try to parse clix payload from a JSON string
    if let clixJsonString = userInfo["clix"] as? String,
      let data = clixJsonString.data(using: .utf8)
    {
      do {
        if let clixData = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let messageId = clixData["message_id"] as? String
        {
          return messageId
        }
      } catch {
        NSLog("[ClixNotificationServiceExtension] Failed to decode clix payload JSON: \(error.localizedDescription)")
      }
    }

    return nil
  }
}
