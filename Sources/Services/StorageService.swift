import Foundation

/// Service responsible for handling persistent storage operations
actor StorageService {
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  /// Set value to storage
  /// - Parameters:
  ///   - value: Value to save
  ///   - key: Key to save value under
  func set<T>(_ value: T?, forKey key: String) {
    if let value = value {
      let wrapped = AnyEncodable(value)
      userDefaults.set(wrapped, forKey: key)
    } else {
      userDefaults.removeObject(forKey: key)
    }
  }

  /// Get value from storage
  /// - Parameters:
  ///   - key: Key to get value for
  /// - Returns: Value if found and can be converted to specified type, nil otherwise
  func get<T>(forKey key: String) -> T? {
    guard let wrapped = userDefaults.object(forKey: key) as? AnyDecodable else {
      return nil
    }
    return wrapped.value as? T
  }

  /// Remove value from storage
  /// - Parameter key: Key to remove value for
  func remove(forKey key: String) {
    userDefaults.removeObject(forKey: key)
  }
}
