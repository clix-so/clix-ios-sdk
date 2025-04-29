import Foundation

class EventService {
  private let eventAPI: EventAPIService

  init(eventAPI: EventAPIService = EventAPIService.shared) {
    self.eventAPI = eventAPI
  }

  func trackEvent(name: String, properties: [String: Any]?, userId: String?) async throws {
    try await eventAPI.trackEvent(name: name, properties: properties, userId: userId)
  }

  func reset() {
    UserDefaults.standard.removeObject(forKey: "clix_last_event_timestamp")
    UserDefaults.standard.removeObject(forKey: "clix_event_queue")
  }
}
