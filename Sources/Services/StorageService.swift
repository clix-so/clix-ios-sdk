import Foundation

/// Service responsible for handling persistent storage operations
class StorageService {
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  /// Save data to storage
  /// - Parameters:
  ///   - data: Data to save
  ///   - key: Key to save data under
  func save(_ data: Data, forKey key: String) {
    userDefaults.set(data, forKey: key)
  }

  /// Load data from storage
  /// - Parameter key: Key to load data for
  /// - Returns: Data if found, nil otherwise
  func load(forKey key: String) -> Data? {
    userDefaults.data(forKey: key)
  }

  /// Save encodable object to storage
  /// - Parameters:
  ///   - object: Object to save
  ///   - key: Key to save object under
  /// - Throws: Encoding error if object cannot be encoded
  func save<T: Encodable>(_ object: T, forKey key: String) throws {
    let data = try JSONEncoder().encode(object)
    save(data, forKey: key)
  }

  /// Load decodable object from storage
  /// - Parameters:
  ///   - type: Type of object to load
  ///   - key: Key to load object for
  /// - Returns: Decoded object if found, nil otherwise
  /// - Throws: Decoding error if data cannot be decoded
  func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
    guard let data = load(forKey: key) else {
      return nil
    }
    return try JSONDecoder().decode(type, from: data)
  }

  /// Remove data from storage
  /// - Parameter key: Key to remove data for
  func remove(forKey key: String) {
    userDefaults.removeObject(forKey: key)
  }

  /// Check if data exists for key
  /// - Parameter key: Key to check
  /// - Returns: True if data exists, false otherwise
  func exists(forKey key: String) -> Bool {
    userDefaults.object(forKey: key) != nil
  }
}
