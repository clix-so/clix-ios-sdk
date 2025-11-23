import Foundation
import MMKV

actor MmkvStorage: Storage {
  private let mmkv: MMKV
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  init(projectId: String, appGroupId: String?) {
    let mmapID = "clix.\(projectId)"

    let appGroupDir = appGroupId.flatMap {
      FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: $0
      )?.path
    }

    if let appGroupDir = appGroupDir, let appGroupId = appGroupId {
      ClixLogger.debug("Initializing MMKV with app group: \(appGroupId)")
      MMKV.initialize(rootDir: nil, groupDir: appGroupDir, logLevel: .info)
    } else {
      ClixLogger.debug("Initializing MMKV with default directory")
      MMKV.initialize(rootDir: nil)
    }

    if let instance = MMKV(mmapID: mmapID, mode: .multiProcess) {
      ClixLogger.debug("Successfully initialized MMKV instance: \(mmapID)")
      self.mmkv = instance
    } else {
      ClixLogger.error("Failed to initialize MMKV instance with mmapID: \(mmapID), attempting fallback with different mmapID")
      let fallbackMmapID = "clix.fallback.\(projectId)"
      if let fallbackInstance = MMKV(mmapID: fallbackMmapID, mode: .singleProcess) {
        ClixLogger.warn("Using fallback MMKV instance: \(fallbackMmapID)")
        self.mmkv = fallbackInstance
      } else if let defaultInstance = MMKV.default() {
        ClixLogger.error("Using MMKV.default() - data may mix with other apps")
        self.mmkv = defaultInstance
      } else {
        ClixLogger.error("Critical: All MMKV initialization attempts failed")
        fatalError("Unable to initialize any MMKV storage. Please check MMKV library installation.")
      }
    }
  }

  func set<T: Codable>(_ key: String, _ value: T?) {
    if let value = value {
      if let encoded = try? encoder.encode(value) {
        mmkv.set(encoded, forKey: key)
      }
    } else {
      mmkv.removeValue(forKey: key)
    }
  }

  func get<T: Codable>(_ key: String) -> T? {
    guard let data = mmkv.data(forKey: key) else {
      return nil
    }
    return try? decoder.decode(T.self, from: data)
  }

  func getWithRetry<T: Codable>(_ key: String, fallbackValue: T, retryDelayMs: UInt64 = 50) async -> T {
    var value: T? = get(key)

    if value == nil {
      ClixLogger.debug("Value not immediately available, checking MMKV sync...")
      synchronize()
      try? await Task.sleep(nanoseconds: retryDelayMs * 1_000_000)
      value = get(key)
    }

    let result = value ?? fallbackValue
    ClixLogger.info("Retrieved value source: \(value != nil ? "stored" : "fallback")")
    return result
  }

  func remove(_ key: String) {
    mmkv.removeValue(forKey: key)
  }

  func synchronize() {
    mmkv.sync()
  }
}
