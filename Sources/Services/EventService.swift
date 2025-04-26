import Foundation

class EventService {
  private let networkService: NetworkService

  init(networkService: NetworkService = NetworkService.shared) {
    self.networkService = networkService
  }

  func trackEvent(name: String, properties: [String: Any]?, userId: String?) async throws {
    try await networkService.trackEvent(name: name, properties: properties, userId: userId)
  }

  func reset() {
    UserDefaults.standard.removeObject(forKey: "clix_last_event_timestamp")
    UserDefaults.standard.removeObject(forKey: "clix_event_queue")
  }
}
