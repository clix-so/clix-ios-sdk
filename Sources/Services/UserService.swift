import Foundation

class UserService {
  private let visitorApiService = VisitorAPIService()
  private let tokenService = TokenService()
  private var currentUser = ClixUser()

  func getCurrentUser() -> ClixUser {
    currentUser
  }

  func setUserId(_ userId: String) async throws {
    currentUser.userId = userId
    try await visitorApiService.setUserId(userId)
  }

  func removeUserId() async throws {
    if let userId = currentUser.userId {
      try await visitorApiService.removeUserId(userId)
    }
    currentUser.userId = nil
  }

  func setProperties(_ properties: [String: Any]) async throws {
    try await visitorApiService.setProperties(properties)
  }

  func removeProperties(_ keys: [String]) async throws {
    let properties: [String: Any?] = Dictionary(uniqueKeysWithValues: keys.map { ($0, nil) })
    try await visitorApiService.setProperties(properties)
  }

  func registerDevice(token: String) async throws {
    try await visitorApiService.registerDevice(token: token)
  }
}
