import Foundation

struct EventRequestBody: Codable {
  let device_id: String
  let name: String
  let event_property: [String: [String: AnyCodable]]  // expects ["custom_properties": ...]
}

class EventAPIService: ClixAPIClient {
  func trackEvent(deviceId: String, name: String, properties: [String: AnyCodable]? = nil) async throws {
    let event = EventRequestBody(
      device_id: deviceId,
      name: name,
      event_property: ["custom_properties": properties ?? [:]]
    )
    let path = "/events"
    let body = ["events": [event]]
    let _: [EventRequestBody] = try await post(path: path, data: body)
  }
}
