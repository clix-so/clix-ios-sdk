import Foundation

/// A model representing a Clix visitor
struct Visitor: Codable {
  /// The unique identifier for the visitor
  let visitorId: String

  /// The unique identifier for the Project user
  var userId: String?

  /// The visitor's properties
  var properties: [String: AnyCodable]?

  /// Creates a new Visitor instance
  /// - Parameters:
  ///   - visitorId: The unique identifier for the visitor
  ///   - userId: The unique identifier for the Project user
  ///   - properties: The visitor's properties
  init(visitorId: String, userId: String? = nil, properties: [String: AnyCodable]? = nil) {
    self.visitorId = visitorId
    self.userId = userId
    self.properties = properties
  }
}
