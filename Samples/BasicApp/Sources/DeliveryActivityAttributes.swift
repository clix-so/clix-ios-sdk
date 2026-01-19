import ActivityKit
import Foundation

struct DeliveryActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var status: String
    var estimatedDeliveryTime: String
  }

  var orderNumber: String
  var restaurantName: String
}
