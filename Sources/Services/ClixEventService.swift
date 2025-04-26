import Foundation

class ClixEventService {
  private let networkService: ClixNetworkService

  init(networkService: ClixNetworkService = ClixNetworkService.shared) {
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
