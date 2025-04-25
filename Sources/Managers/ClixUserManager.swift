import Foundation

class ClixUserManager {
  private let networkManager: ClixNetworkManager

  init(networkManager: ClixNetworkManager = ClixNetworkManager.shared) {
    self.networkManager = networkManager
  }

  func registerDevice(token: String, userId: String?) async throws {
    try await networkManager.registerDevice(token: token, userId: userId)
  }

  func setAttribute(_ key: String, value: Any) async throws {
    try await networkManager.setAttribute(key: key, value: value)
  }

  func reset() {
    UserDefaults.standard.removeObject(forKey: "clix_user_attributes")
    UserDefaults.standard.removeObject(forKey: "clix_user_id")
  }
}
