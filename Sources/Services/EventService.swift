import Foundation

class EventService {
  private let apiService = EventAPIService()

  func trackEvent(name: String, properties: [String: Any?] = [:], messageId: String? = nil) async throws {
    do {
      let environment = try Clix.shared.get(\.environment)
      let deviceId = environment.getDevice().id
      let eventProperties = properties.compactMapValues { $0 }.mapValues { AnyCodable($0) }
      try await apiService.trackEvent(deviceId: deviceId, name: name, properties: eventProperties, messageId: messageId)
    } catch {
      ClixLogger.error("Failed to track event '\(name)': \(error). Make sure Clix.initialize() has been called.")
      throw error
    }
  }
}
