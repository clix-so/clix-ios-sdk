import Foundation

actor UserService {
  private let visitorApiService = VisitorAPIService()
  private let tokenService = TokenService()
  private let storageService = StorageService()
  private let clixUserKey = "clix_user"
  private var currentUser: ClixUser?

  private func generateVisitorId() -> String {
    UUID(uuidString: DeviceUtil.getDeviceId())?.uuidString ?? UUID().uuidString
  }

  /// Get current user, creating a new one if it doesn't exist
  /// - Returns: Current ClixUser instance
  func getCurrentUser() async -> ClixUser {
    if let user = currentUser {
      return user
    }

    if let storedUser: ClixUser = await storageService.get(forKey: clixUserKey) {
      currentUser = storedUser
      return storedUser
    }

    let newUser = ClixUser(visitorId: generateVisitorId())
    currentUser = newUser
    await storageService.set(newUser, forKey: clixUserKey)
    return newUser
  }

  func setUserId(_ userId: String) async throws {
    let user = await getCurrentUser()
    user.setUserId(userId)
    await storageService.set(user, forKey: clixUserKey)
    try await visitorApiService.setUserId(userId)
  }

  func removeUserId() async throws {
    let user = await getCurrentUser()
    if let userId = user.userId {
      try await visitorApiService.removeUserId(userId)
    }
    user.setUserId(nil)
    await storageService.set(user, forKey: clixUserKey)
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
