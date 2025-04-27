import Foundation

class UserService {
  private let networkService: NetworkService
  private var currentUser: ClixUser

  static let userDefaultsKey = "clix_user_data"

  init(networkService: NetworkService = NetworkService.shared) {
    self.networkService = networkService
    self.currentUser = UserService.loadUserFromStorage() ?? ClixUser()
  }

  // MARK: - User Management

  /// Returns the current user
  func getCurrentUser() -> ClixUser {
    currentUser
  }

  /// Sets the user ID and persists the change
  /// - Parameter userId: The user ID to set
  func setUserId(_ userId: String) {
    currentUser.userId = userId
    saveUserToStorage()
  }

  /// Removes the user ID
  func removeUserId() {
    currentUser.userId = nil
    saveUserToStorage()
  }

  /// Sets a user attribute and persists the change
  /// - Parameters:
  ///   - key: Attribute key
  ///   - value: Attribute value
  func setAttribute(_ key: String, value: Any?) async throws {
    // Initialize userAttributes if nil
    if currentUser.userAttributes == nil {
      currentUser.userAttributes = [:]
    }

    // Convert value to AttributeValue
    let attributeValue = ClixUser.AttributeValue.from(value)
    currentUser.userAttributes?[key] = attributeValue
    saveUserToStorage()

    // Send to server
    try await networkService.setAttribute(key: key, value: value ?? NSNull(), userId: currentUser.userId)
  }

  /// Sets multiple user attributes at once and persists the changes
  /// - Parameter userAttributes: Dictionary of attribute keys and values
  func setAttributes(_ userAttributes: [String: Any?]) async throws {
    // Initialize userAttributes if nil
    if currentUser.userAttributes == nil {
      currentUser.userAttributes = [:]
    }

    // First update local storage to ensure we persist even if network fails
    for (key, value) in userAttributes {
      let attributeValue = ClixUser.AttributeValue.from(value)
      currentUser.userAttributes?[key] = attributeValue
    }
    saveUserToStorage()

    // Then update each attribute on the server
    for (key, value) in userAttributes {
      try await networkService.setAttribute(key: key, value: value ?? NSNull(), userId: currentUser.userId)
    }
  }

  /// Remove a user attribute
  /// - Parameter key: Attribute key to remove
  func removeAttribute(_ key: String) async throws {
    currentUser.userAttributes?[key] = nil
    saveUserToStorage()

    // Also update server
    try await networkService.setAttribute(key: key, value: NSNull(), userId: currentUser.userId)
  }

  /// Get a user attribute
  /// - Parameter key: Attribute key
  /// - Returns: Attribute value if exists, nil otherwise
  func getAttribute(_ key: String) -> Any? {
    currentUser.userAttributes?[key]?.value
  }

  /// Get all user attributes
  /// - Returns: Dictionary with all user attributes
  func getAllAttributes() -> [String: Any] {
    var result: [String: Any] = [:]

    guard let userAttributes = currentUser.userAttributes else {
      return result
    }

    for (key, attributeValue) in userAttributes {
      result[key] = attributeValue.value
    }

    return result
  }

  /// Register device with the server
  /// - Parameters:
  ///   - token: Device token
  ///   - userId: User ID
  func registerDevice(token: String, userId: String?) async throws {
    try await networkService.registerDevice(token: token, userId: userId)
  }

  // MARK: - Storage

  /// Saves the current user to persistent storage
  private func saveUserToStorage() {
    if let encoded = try? JSONEncoder().encode(currentUser) {
      UserDefaults.standard.set(encoded, forKey: UserService.userDefaultsKey)
    }
  }

  /// Loads the user from persistent storage
  /// - Returns: ClixUser if found, nil otherwise
  private static func loadUserFromStorage() -> ClixUser? {
    guard let userData = UserDefaults.standard.data(forKey: userDefaultsKey),
      let user = try? JSONDecoder().decode(ClixUser.self, from: userData)
    else {
      return nil
    }
    return user
  }

  /// Resets all user data
  func reset() {
    currentUser = ClixUser()
    UserDefaults.standard.removeObject(forKey: UserService.userDefaultsKey)
  }
}
