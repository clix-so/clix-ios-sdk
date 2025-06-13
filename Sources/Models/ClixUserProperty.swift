import Foundation

public struct ClixUserProperty: Codable {
  public enum PropertyType: String, Codable {
    case string = "USER_PROPERTY_TYPE_STRING"
    case number = "USER_PROPERTY_TYPE_NUMBER"
    case boolean = "USER_PROPERTY_TYPE_BOOLEAN"
  }

  public let name: String
  public let value_string: AnyCodable  // swiftlint:disable:this identifier_name
  public let type: PropertyType

  public init(name: String, value: AnyCodable, type: PropertyType) {
    self.name = name
    self.value_string = value
    self.type = type
  }

  public static func of(name: String, value: Any) -> ClixUserProperty {
    switch value {
    case let typedValue as Bool:
      return ClixUserProperty(name: name, value: AnyCodable(typedValue), type: .boolean)
    case let typedValue as NSNumber:
      return ClixUserProperty(name: name, value: AnyCodable(typedValue), type: .number)
    case let typedValue as String:
      return ClixUserProperty(name: name, value: AnyCodable(typedValue), type: .string)
    default:
      return ClixUserProperty(name: name, value: AnyCodable(String(describing: value)), type: .string)
    }
  }
}
