import Foundation

struct ClixPushNotificationPayload: Codable {
  let messageId: String
  let campaignId: String?
  let userId: String?
  let deviceId: String?
  let trackingId: String?
  let landingUrl: String?
  let imageUrl: String?
  let userJourneyId: String?
  let userJourneyNodeId: String?
  let customProperties: [String: AnyCodable]?
}

extension ClixPushNotificationPayload {
  static func decode(from userInfo: [AnyHashable: Any]) -> ClixPushNotificationPayload? {
    guard let clixValue = userInfo["clix"] else { return nil }

    let data: Data?
    if let clixDict = clixValue as? [String: Any] {
      guard JSONSerialization.isValidJSONObject(clixDict) else { return nil }
      data = try? JSONSerialization.data(withJSONObject: clixDict)
    } else if let clixString = clixValue as? String {
      data = clixString.data(using: .utf8)
    } else {
      data = nil
    }

    guard let jsonData = data else { return nil }

    return try? JSONDecoder().decode(ClixPushNotificationPayload.self, from: jsonData)
  }
}
