import Foundation

class EventService {
  private let apiService = EventAPIService()

  func trackEvent(name: String, properties: [String: Any?] = [:]) async throws {
    try await apiService.trackEvent(name: name, properties: properties)
  }
}
