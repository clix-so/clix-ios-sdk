import Foundation

class EventAPIService: ClixAPIClient {
  func trackEvent(name: String, properties: [String: Any?] = [:]) async throws {
    let visitorId = await Clix.shared.userService.getCurrentUser().visitorId
    var eventProperties = properties
    eventProperties["visitorId"] = visitorId
    let path = "/v1/events"
    let _: AnyCodable = try await post(path: path, data: eventProperties)
  }
}
