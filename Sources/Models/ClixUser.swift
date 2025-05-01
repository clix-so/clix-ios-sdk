import Foundation
import UIKit

/// A model representing a Clix user with their userProperties
class ClixUser: Codable {
  /// The unique identifier for the Clix visitor
  let visitorId: String

  /// The unique identifier for the Project user
  var userId: String?

  init(visitorId: String, userId: String? = nil) {
    self.visitorId = visitorId
    self.userId = userId
  }

  func setUserId(_ userId: String?) {
    self.userId = userId
  }
}
