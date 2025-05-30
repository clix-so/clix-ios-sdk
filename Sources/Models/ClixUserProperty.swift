import Foundation

public struct ClixUserProperty: Codable {
    public enum PropertyType: String, Codable {
        case string = "USER_PROPERTY_TYPE_STRING"
        case number = "USER_PROPERTY_TYPE_NUMBER"
        case boolean = "USER_PROPERTY_TYPE_BOOLEAN"
    }

    public let name: String
    public let value_string: AnyCodable
    public let type: PropertyType

    public init(name: String, value_string: AnyCodable, type: PropertyType) {
        self.name = name
        self.value_string = value_string
        self.type = type
    }

    public static func of(name: String, value: Any) -> ClixUserProperty {
        switch value {
        case let typedValue as Bool:
            return ClixUserProperty(name: name, value_string: AnyCodable(typedValue), type: .boolean)
        case let typedValue as NSNumber:
            return ClixUserProperty(name: name, value_string: AnyCodable(typedValue), type: .number)
        case let typedValue as String:
            return ClixUserProperty(name: name, value_string: AnyCodable(typedValue), type: .string)
        default:
            return ClixUserProperty(name: name, value_string: AnyCodable(String(describing: value)), type: .string)
        }
    }
}


