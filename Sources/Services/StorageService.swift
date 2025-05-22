import Foundation

/// Service responsible for handling persistent storage operations
actor StorageService: @unchecked Sendable {
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  /// Set value to storage
  /// - Parameters:
  ///   - value: Value to save
  ///   - key: Key to save value under
  func set<T: Codable>(_ value: T?, forKey key: String) {
    if let value = value {
      let encoder = JSONEncoder()
      if let encoded = try? encoder.encode(value) {
        userDefaults.set(encoded, forKey: key)
      }
    } else {
      userDefaults.removeObject(forKey: key)
    }
  }

  /// Get value from storage
  /// - Parameters:
  ///   - key: Key to get value for
  /// - Returns: Value if found and can be converted to specified type, nil otherwise
  func get<T: Codable>(forKey key: String) -> T? {
    guard let data = userDefaults.data(forKey: key) else {
      return nil
    }
    let decoder = JSONDecoder()
    return try? decoder.decode(T.self, from: data)
  }

  /// Remove value from storage
  /// - Parameter key: Key to remove value for
  func remove(forKey key: String) {
    userDefaults.removeObject(forKey: key)
  }
}
