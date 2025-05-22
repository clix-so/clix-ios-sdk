@preconcurrency import Foundation
import UIKit
import UserNotifications

/// Main class of Clix SDK
public actor Clix {
  // MARK: - Properties

  var config = ClixConfig()
  private let storageService = StorageService()
  internal lazy var tokenService = TokenService(storageService: storageService)
  internal lazy var deviceService = DeviceService(storageService: storageService, tokenService: tokenService)
  internal lazy var eventService = EventService()
  internal lazy var notificationService = NotificationService(storageService: storageService)
  private var environment: ClixEnvironment?

  private func setConfig(_ config: ClixConfig) {
    self.config = config
  }

  private func getOrCreateDeviceId() async -> String {
    let key = "clix_device_id"
    if let id: String = await storageService.get(forKey: key) {
      return id
    }
    let newId = UUID().uuidString
    await storageService.set(newId, forKey: key)
    return newId
  }

  func setEnvironment(_ env: ClixEnvironment) {
    self.environment = env
  }

  func getEnvironment() -> ClixEnvironment? {
    self.environment
  }
}

public extension Clix {
  internal static let version = "1.0.0"
  internal static var shared = Clix()

  /// Initialize the Clix SDK
  /// - Parameters:
  ///   - config: ClixConfig SDK configuration
  static func initialize(config: ClixConfig) async throws {
    ClixLogger.setLogLevel(config.logLevel)
    let deviceId = await shared.getOrCreateDeviceId()
    await shared.setEnvironment(await ClixEnvironment(config: config, deviceId: deviceId))
    await shared.setConfig(config)
  }

  /// Sets the user ID
  /// - Parameters:
  ///   - userId: User ID to set
  static func setUserId(_ userId: String) async throws {
    try await shared.deviceService.setProjectUserId(userId)
  }

  /// Removes the user ID
  static func removeUserId() async throws {
    try await shared.deviceService.removeProjectUserId()
  }

  /// Sets a user property
  /// - Parameters:
  ///   - key: Property key
  ///   - value: Property value
  static func setUserProperty(_ key: String, value: Any) async throws {
    try await shared.deviceService.updateUserProperties([key: value])
  }

  /// Sets multiple user properties at once
  /// - Parameter userProperties: Dictionary of property keys and values
  static func setUserProperties(_ userProperties: [String: Any]) async throws {
    try await shared.deviceService.updateUserProperties(userProperties)
  }

  /// Removes a user property
  /// - Parameter key: Property key to remove
  static func removeUserProperty(_ key: String) async throws {
    try await shared.deviceService.removeUserProperties([key])
  }

  /// Removes multiple user properties
  /// - Parameter keys: Property keys to remove
  static func removeUserProperties(_ keys: [String]) async throws {
    try await shared.deviceService.removeUserProperties(keys)
  }

  /// Tracks an event
  /// - Parameters:
  ///   - name: Event name
  ///   - properties: Event properties
  static func trackEvent(_ name: String, properties: [String: Any?] = [:]) async throws {
    try await shared.eventService.trackEvent(name: name, properties: properties)
  }

  /// Sets the logging level
  /// - Parameter level: Logging level to set
  static func setLogLevel(_ level: ClixLogLevel) {
    ClixLogger.setLogLevel(level)
  }

  static func getDevice() async -> ClixDevice? {
    await shared.getEnvironment()?.getDevice()
  }

  static func setDevice(_ device: ClixDevice) async {
    await shared.getEnvironment()?.setDevice(device)
  }

  /// Indicates whether AppDelegate method swizzling is enabled for Firebase integration.
  /// Default is `true`. Set to `false` to disable swizzling.
  static var isSwizzlingEnabledForAppDelegate: Bool = true
}
