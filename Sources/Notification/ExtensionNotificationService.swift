import Foundation

/// Service class to handle notification events in extensions
/// Uses ExtensionAPIClient to communicate with the server
class ExtensionNotificationService {
  private let apiClient = ExtensionAPIClient()

  /// Handle push notification received event
  /// Makes the same request as NotificationService.handlePushReceived
  func handlePushReceived(userInfo: [AnyHashable: Any]) async {
    if let messageId = getMessageId(userInfo: userInfo) {
      do {
        let payload: [String: Any] = [
          "event": "PUSH_NOTIFICATION_RECEIVED",
          "message_id": messageId,
          "timestamp": ISO8601DateFormatter().string(from: Date()),
        ]

        // Use EmptyResponse as we don't need to parse the response
        let _: EmptyResponse = try await apiClient.post(path: "/events", data: payload)
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
