import Foundation

/// A model representing a Clix push notification payload
public struct ClixPushNotificationPayload: Codable {
  public let messageId: String
  public let landingUrl: String?
  public let imageUrl: String?

  public init(
    messageId: String,
    landingUrl: String?,
    imageUrl: String?
  ) {
    self.messageId = messageId
    self.landingUrl = landingUrl
    self.imageUrl = imageUrl
  }
}
