import Foundation

struct ClixPushNotificationPayload: Codable {
  let messageId: String
  let imageUrl: String?
  let landingUrl: String?
  let userJourneyId: String?
  let userJourneyNodeId: String?
}

extension ClixPushNotificationPayload {
  static func decode(from userInfo: [AnyHashable: Any]) -> ClixPushNotificationPayload? {
    guard let clixValue = userInfo["clix"] else {
      ClixLogger.debug("No 'clix' key found in userInfo")
      return nil
    }

    let data: Data?
    if let clixDict = clixValue as? [String: Any] {
      guard JSONSerialization.isValidJSONObject(clixDict) else {
        ClixLogger.debug("Invalid JSON object in 'clix' dictionary")
        return nil
      }
      do {
        data = try JSONSerialization.data(withJSONObject: clixDict)
      } catch {
        ClixLogger.debug("Failed to serialize 'clix' dictionary to JSON data", error: error)
        return nil
      }
    } else if let clixString = clixValue as? String {
      data = clixString.data(using: .utf8)
      if data == nil {
        ClixLogger.debug("Failed to convert 'clix' string to UTF-8 data")
      }
    } else {
      ClixLogger.debug("'clix' value is neither dictionary nor string")
      data = nil
    }

    guard let jsonData = data else {
      ClixLogger.debug("Failed to obtain JSON data from 'clix' value")
      return nil
    }

    do {
      return try JSONDecoder().decode(ClixPushNotificationPayload.self, from: jsonData)
    } catch {
      ClixLogger.debug("Failed to decode ClixPushNotificationPayload from JSON", error: error)
      return nil
    }
  }
}
