import Foundation

struct ClixPushNotificationPayload: Codable {
  let messageId: String
  let campaignId: String?
  let userId: String?
  let deviceId: String?
  let trackingId: String?
  let landingUrl: String?
  let imageUrl: String?
  let customProperties: [String: AnyCodable]?
}
