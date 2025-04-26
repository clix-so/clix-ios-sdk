import Foundation

class ClixUserService {
  private let networkService: ClixNetworkService

  init(networkService: ClixNetworkService = ClixNetworkService.shared) {
    self.networkService = networkService
  }

  func registerDevice(token: String, userId: String?) async throws {
    try await networkService.registerDevice(token: token, userId: userId)
  }

  func setAttribute(_ key: String, value: Any) async throws {
    try await networkService.setAttribute(key: key, value: value)
  }

  func reset() {
    UserDefaults.standard.removeObject(forKey: "clix_user_attributes")
    UserDefaults.standard.removeObject(forKey: "clix_user_id")
  }
}
