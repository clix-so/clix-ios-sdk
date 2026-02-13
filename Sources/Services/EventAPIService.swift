import Foundation

struct EventRequestBody: Codable {
  let deviceId: String
  let name: String
  let sourceType: String?
  let properties: [String: AnyCodable]  // expects ["custom_properties": ...]
}

struct EventResponseBody: Codable {
  let userId: String?
  let deviceId: String
  let name: String
  let properties: [String: AnyCodable]
}

struct EventsResponse: Codable {
  let events: [EventResponseBody]
}

class EventAPIService: ClixAPIClient {
  func trackEvent(
    deviceId: String,
    name: String,
    properties: [String: AnyCodable]? = nil,
    messageId: String? = nil,
    userJourneyId: String? = nil,
    userJourneyNodeId: String? = nil,
    sourceType: String? = nil
  )
    async throws
  {
    let event = EventRequestBody(
      deviceId: deviceId,
      name: name,
      sourceType: sourceType,
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
