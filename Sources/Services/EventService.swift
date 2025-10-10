import Foundation

extension NSNumber {
  var isBool: Bool {
    return CFGetTypeID(self) == CFBooleanGetTypeID()
  }
}

class EventService {
  private let apiService = EventAPIService()
  
  private let dateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
    formatter.timeZone = TimeZone.current
    return formatter
  }()

  func trackEvent(
    name: String,
    properties: [String: Any?] = [:],
    messageId: String? = nil,
    userJourneyId: String? = nil,
    userJourneyNodeId: String? = nil
  ) async throws {
    do {
      let environment = try Clix.shared.get(\.environment)
      let deviceId = environment.getDevice().id
      let eventProperties = properties.compactMapValues { $0 }.mapValues { value -> AnyCodable in
        switch value {
        case let number as NSNumber:
          if number.isBool {
            return AnyCodable(number.boolValue)
          } else {
            return AnyCodable(number.doubleValue)
          }
        case let string as String:
          return AnyCodable(string)
        case let date as Date:
          let isoString = dateFormatter.string(from: date)
          return AnyCodable(isoString)
        default:
          return AnyCodable(String(describing: value))
        }
      }
      
      try await apiService.trackEvent(
        deviceId: deviceId,
        name: name,
        properties: eventProperties,
        messageId: messageId,
        userJourneyId: userJourneyId,
        userJourneyNodeId: userJourneyNodeId
      )
    } catch {
      ClixLogger.error("Failed to track event '\(name)': \(error). Make sure Clix.initialize() has been called.")
      throw error
    }
  }
}
