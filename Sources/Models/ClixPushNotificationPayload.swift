import Foundation

struct ClixPushNotificationPayload: Codable {
  let messageId: String
  let title: String?
  let body: String?
  let imageUrl: String?
  let landingUrl: String?
  let userJourneyId: String?
  let userJourneyNodeId: String?
}

extension ClixPushNotificationPayload {
  static func decode(from userInfo: [AnyHashable: Any]) -> ClixPushNotificationPayload? {
    guard let clixValue = userInfo["clix"] else {
      ClixLogger.error("Failed to decode 'clix' from userInfo: \(userInfo)")
      return nil
    }

    let dataFromDict = (clixValue as? [String: Any]).flatMap { try? JSONSerialization.data(withJSONObject: $0) }
    let dataFromString = (clixValue as? String)?.data(using: .utf8)

    guard let data = dataFromDict ?? dataFromString else {
      ClixLogger.error("Failed to decode 'clix' from userInfo: \(userInfo)")
      return nil
    }

    guard let payload = try? ClixJSONCoders.decoder.decode(ClixPushNotificationPayload.self, from: data) else {
      ClixLogger.error("Failed to decode 'clix' from userInfo: \(userInfo)")
      return nil
    }

    return payload
  }
}
