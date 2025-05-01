import Foundation
import UIKit

/// A model representing a Clix user with their userProperties
struct ClixUser: Codable {
  /// The unique identifier for the Clix visitor
  let visitorId: String

  /// The unique identifier for the Project user
  var userId: String?

  /// Creates a new ClixUser instance
  /// - Parameters:
  ///   - userId: The unique identifier for the Project user
  init(userId: String? = nil) {
    self.visitorId = ClixUser.generateVisitorId()
    self.userId = userId
  }

  private static func generateVisitorId() -> String {
    UUID(uuidString: DeviceUtil.getDeviceId())?.uuidString ?? UUID().uuidString
  }
}
