import Foundation

actor EventService {
  private let apiService = EventAPIService()

  func trackEvent(name: String, properties: [String: Any?] = [:], messageId: String? = nil) async throws {
    guard let deviceId = await Clix.shared.getEnvironment()?.deviceId else { return }
    let eventProperties = properties.compactMapValues { $0 }.mapValues { AnyCodable($0) }
    try await apiService.trackEvent(deviceId: deviceId, name: name, properties: eventProperties, messageId: messageId)
  }
}
