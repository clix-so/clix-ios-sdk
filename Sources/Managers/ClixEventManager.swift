import Foundation

class ClixEventManager {
  private let networkManager: ClixNetworkManager

  init(networkManager: ClixNetworkManager = ClixNetworkManager.shared) {
    self.networkManager = networkManager
  }

  func trackEvent(name: String, properties: [String: Any]?, userId: String?) async throws {
    try await networkManager.trackEvent(name: name, properties: properties, userId: userId)
  }

  func reset() {
    UserDefaults.standard.removeObject(forKey: "clix_last_event_timestamp")
    UserDefaults.standard.removeObject(forKey: "clix_event_queue")
  }
}
