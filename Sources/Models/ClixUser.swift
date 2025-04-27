import Foundation

/// A model representing a Clix user with their userAttributes
public struct ClixUser: Codable {
  /// The unique identifier for the user
  public var userId: String?

  /// The userAttributes associated with the user
  public var userAttributes: [String: AttributeValue]?

  /// Creates a new ClixUser instance
  /// - Parameters:
  ///   - userId: The unique identifier for the user
  ///   - userAttributes: The userAttributes associated with the user
  public init(userId: String? = nil, userAttributes: [String: AttributeValue]? = nil) {
    self.userId = userId
    self.userAttributes = userAttributes ?? [:]
  }

  /// Represents possible values for user userAttributes
  public enum AttributeValue: Codable, Equatable {
    case string(String)
    case number(Double)
    case boolean(Bool)
    case null

    public init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()

      if container.decodeNil() {
        self = .null
      } else if let stringValue = try? container.decode(String.self) {
        self = .string(stringValue)
      } else if let boolValue = try? container.decode(Bool.self) {
        self = .boolean(boolValue)
      } else if let numberValue = try? container.decode(Double.self) {
        self = .number(numberValue)
      } else {
        throw DecodingError.dataCorruptedError(
          in: container,
          debugDescription: "Cannot decode user attribute"
        )
      }
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()

      switch self {
      case .string(let value):
        try container.encode(value)
      case .number(let value):
        try container.encode(value)
      case .boolean(let value):
        try container.encode(value)
      case .null:
        try container.encodeNil()
      }
    }

    /// Creates an AttributeValue from any value, converting complex types to strings
    /// - Parameter value: The value to convert
    /// - Returns: An AttributeValue representation of the input
    public static func from(_ value: Any?) -> AttributeValue {
      guard let value = value else {
        return .null
      }

      switch value {
      case let stringValue as String:
        return .string(stringValue)
      case let numberValue as NSNumber:
        // Handle both numbers and booleans
        guard CFGetTypeID(numberValue) == CFBooleanGetTypeID() else {
          return .number(numberValue.doubleValue)
        }
        return .boolean(numberValue.boolValue)
      case let intValue as Int:
        return .number(Double(intValue))
      case let doubleValue as Double:
        return .number(doubleValue)
      case let floatValue as Float:
        return .number(Double(floatValue))
      case let boolValue as Bool:
        return .boolean(boolValue)
      default:
        // For nested objects, dictionaries, arrays, or any other complex type
        // Convert to JSON string if possible, otherwise use description
        if JSONSerialization.isValidJSONObject(value) {
          if let data = try? JSONSerialization.data(withJSONObject: value),
            let jsonString = String(data: data, encoding: .utf8) {
            return .string(jsonString)
          }
        }
        // Fallback to description
        return .string(String(describing: value))
      }
    }

    /// Returns the underlying value
    public var value: Any? {
      switch self {
      case .string(let value): return value
      case .number(let value): return value
      case .boolean(let value): return value
      case .null: return nil
      }
    }
  }
}
