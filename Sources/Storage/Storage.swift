import Foundation

protocol Storage: Actor {
  func set<T: Codable>(_ key: String, _ value: T?)
  func get<T: Codable>(_ key: String) -> T?
  func getWithRetry<T: Codable>(_ key: String, fallbackValue: T, retryDelayMs: UInt64) async -> T
  func remove(_ key: String)
  func synchronize()
}
