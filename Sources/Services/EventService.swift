import Foundation

class EventService {
  private let apiService: EventAPIService

  init(eventAPI: EventAPIService = EventAPIService()) {
    self.apiService = eventAPI
  }

  func trackEvent(name: String, properties: [String: Any]?, userId: String?) async throws {
    try await apiService.trackEvent(name: name, properties: properties, userId: userId)
  }
}
