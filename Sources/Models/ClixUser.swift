import Foundation

/// A model representing a Clix user with their userAttributes
public struct ClixUser: Codable {
  /// The unique Clix identifier for the user
  public var clixId: String?

  /// The unique identifier for the user
  public var userId: String?

  /// The userAttributes associated with the user
  public var userAttributes: [String: AnyCodable]?

  /// Creates a new ClixUser instance
  /// - Parameters:
  ///   - userId: The unique identifier for the user
  ///   - clixId: The unique Clix identifier for the user
  ///   - userAttributes: The userAttributes associated with the user
  public init(userId: String? = nil, clixId: String? = nil, userAttributes: [String: AnyCodable]? = nil) {
    self.userId = userId
    self.clixId = clixId
    self.userAttributes = userAttributes ?? [:]
  }

  /// Type to represent any attribute value
  public enum AttributeValue {
    /// Helper method to convert Any? to AnyCodable
    /// - Parameter value: The value to convert
    /// - Returns: AnyCodable representation of the value
    public static func from(_ value: Any?) -> AnyCodable {
      AnyCodable(value)
    }
  }
}
