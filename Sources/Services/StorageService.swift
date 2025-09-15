import Foundation

actor StorageService {
  private let userDefaults: UserDefaults
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()
  private let projectId: String

  init(projectId: String) {
    self.projectId = projectId
    let appGroupId = "group.clix.\(projectId)"
    if let sharedDefaults = UserDefaults(suiteName: appGroupId) {
      ClixLogger.debug("Successfully configured storage with app group: \(appGroupId)")
      self.userDefaults = sharedDefaults
    } else {
      ClixLogger.error("Failed to initialize UserDefaults with app group: \(appGroupId), using standard UserDefaults")
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

  func getWithRetry<T: Codable>(_ key: String, fallbackValue: T, retryDelayMs: UInt64 = 50) async -> T {
    var value: T? = get(key)

    if value == nil {
      ClixLogger.debug("Value not immediately available, checking App Group sync...")
      synchronize()
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
    userDefaults.synchronize()
  }
}
