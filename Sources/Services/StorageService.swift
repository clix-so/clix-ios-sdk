import Foundation

actor StorageService {
  private let storage: any Storage

  init(projectId: String) async {
    self.storage = await StorageInitializer.initializeStorage(projectId: projectId)
  }

  func set<T: Codable>(_ key: String, _ value: T?) async {
    await storage.set(key, value)
  }

  func get<T: Codable>(_ key: String) async -> T? {
    await storage.get(key)
  }

  func getWithRetry<T: Codable>(_ key: String, fallbackValue: T, retryDelayMs: UInt64 = 50) async -> T {
    await storage.getWithRetry(key, fallbackValue: fallbackValue, retryDelayMs: retryDelayMs)
  }

  func remove(_ key: String) async {
    await storage.remove(key)
  }

  func synchronize() async {
    await storage.synchronize()
  }
}
