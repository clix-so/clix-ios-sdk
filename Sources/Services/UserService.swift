import Foundation

class UserService {
  private let visitorApiService: VisitorAPIService
  private var currentUser: ClixUser

  init(visitorApiService: VisitorAPIService = VisitorAPIService()) {
    self.visitorApiService = visitorApiService
    self.currentUser = ClixUser()
  }

  func getCurrentUser() -> ClixUser {
    currentUser
  }

  func setUserId(_ userId: String) {
    currentUser.userId = userId
  }

  func removeUserId() {
    currentUser.userId = nil
  }

  func setProperty(_ key: String, value: AnyCodable) async throws {
    try await apiService.setProperty(userId: currentUser.userId, key: key, value: value)
  }

  func setProperties(_ userProperties: [String: AnyCodable]) async throws {
    for (key, value) in userProperties {
      try await apiService.setProperty(userId: currentUser.userId, key: key, value: value)
    }
  }

  /// Remove a user property
  /// - Parameter key: Property key to remove
  func removeProperty(_ key: String) async throws {
    try await apiService.setProperty(key: key, value: NSNull(), userId: currentUser.userId)
  }

  /// Resets all user data
  func reset() {
    currentUser = ClixUser()
  }
}
