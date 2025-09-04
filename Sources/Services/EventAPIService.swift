import Foundation

// swiftlint:disable identifier_name
struct EventRequestBody: Codable {
  let device_id: String
  let name: String
  let properties: [String: AnyCodable]  // expects ["custom_properties": ...]
}

struct EventResponseBody: Codable {
  let user_id: String?
  let device_id: String
  let name: String
  let properties: [String: AnyCodable]
}

struct EventsResponse: Codable {
  let events: [EventResponseBody]
}
// swiftlint:enable identifier_name

class EventAPIService: ClixAPIClient {
  func trackEvent(
    deviceId: String,
    name: String,
    properties: [String: AnyCodable]? = nil,
    messageId: String? = nil,
    userJourneyId: String? = nil,
    userJourneyNodeId: String? = nil
  )
    async throws
  {
    let event = EventRequestBody(
      device_id: deviceId,
      name: name,
      properties: [
        "custom_properties": AnyCodable(properties ?? [:]), "message_id": AnyCodable(messageId),
        "user_journey_id": AnyCodable(userJourneyId), "user_journey_node_id": AnyCodable(userJourneyNodeId),
      ]
    )
    let path = "/events"
    let body = ["events": [event]]
    let _: EventsResponse = try await post(path: path, data: body)
  }
}
