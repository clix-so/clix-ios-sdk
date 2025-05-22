import Foundation

struct EventRequestBody: Codable {
  let deviceId: String
  let name: String
  let properties: [String: AnyCodable]?
}

class EventAPIService: ClixAPIClient {
  func trackEvent(deviceId: String, name: String, properties: [String: AnyCodable]? = nil) async throws {
    let event = EventRequestBody(deviceId: deviceId, name: name, properties: properties)
    let path = "/events"
    let _: [EventRequestBody] = try await post(path: path, data: [event])
  }
}
