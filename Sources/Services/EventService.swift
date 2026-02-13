import Foundation

extension NSNumber {
  var isBool: Bool {
    CFGetTypeID(self) == CFBooleanGetTypeID()
  }
}

class EventService {
  private let apiService = EventAPIService()
  func trackEvent(
    name: String,
    properties: [String: Any?] = [:],
    messageId: String? = nil,
    userJourneyId: String? = nil,
    userJourneyNodeId: String? = nil,
    sourceType: String? = nil
  ) async throws {
    do {
      let environment = try Clix.shared.get(\.environment)
      let deviceId = environment.getDevice().id
      let eventProperties = properties.compactMapValues { $0 }.mapValues { value -> AnyCodable in
        switch value {
        case let number as NSNumber:
          guard number.isBool else {
            return AnyCodable(number.doubleValue)
          }
          return AnyCodable(number.boolValue)
        case let string as String:
          return AnyCodable(string)
        case let date as Date:
          let isoString = ClixDateFormatter.format(date)
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
        userJourneyNodeId: userJourneyNodeId,
        sourceType: sourceType
      )
    } catch {
      ClixLogger.error("Failed to track event '\(name)': \(error). Make sure Clix.initialize() has been called.")
      throw error
    }
  }
}
