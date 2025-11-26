import Foundation

actor UserDefaultsStorage: Storage {
  private let userDefaults: UserDefaults
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  init(appGroupId: String?) {
    if let appGroupId = appGroupId,
      let sharedDefaults = UserDefaults(suiteName: appGroupId)
    {
      ClixLogger.debug("Initialized UserDefaults with app group: \(appGroupId)")
      self.userDefaults = sharedDefaults
    } else {
      ClixLogger.debug("Initialized UserDefaults with standard storage")
      self.userDefaults = .standard
    }
  }

  func set<T: Codable>(_ key: String, _ value: T?) {
    if let value = value {
      if let encoded = try? encoder.encode(value) {
        userDefaults.set(encoded, forKey: key)
      }
    } else {
      userDefaults.removeObject(forKey: key)
    }
  }

  func get<T: Codable>(_ key: String) -> T? {
    guard let data = userDefaults.data(forKey: key) else {
      return nil
    }
    return try? decoder.decode(T.self, from: data)
  }

  func getRawData(_ key: String) -> Data? {
    userDefaults.data(forKey: key)
  }

  func setRawData(_ key: String, _ data: Data) {
    userDefaults.set(data, forKey: key)
  }

  func getWithRetry<T: Codable>(_ key: String, fallbackValue: T, retryDelayMs: UInt64 = 50) async -> T {
    var value: T? = get(key)

    if value == nil {
      ClixLogger.debug("Value not immediately available, retrying after delay...")
      try? await Task.sleep(nanoseconds: retryDelayMs * 1_000_000)
      value = get(key)
    }

    let result = value ?? fallbackValue
    ClixLogger.info("Retrieved value source: \(value != nil ? "stored" : "fallback")")
    return result
  }

  func remove(_ key: String) {
    userDefaults.removeObject(forKey: key)
  }

  func synchronize() {
    // No-op: UserDefaults automatically persists changes in modern iOS
  }
}
