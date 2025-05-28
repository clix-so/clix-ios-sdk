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
  static func initialize(config: ClixConfig) async {
    ClixLogger.setLogLevel(config.logLevel)
    let deviceId = await shared.getOrCreateDeviceId()
    let environment = await ClixEnvironment(config: config, deviceId: deviceId)
    await shared.setEnvironment(environment)
    await shared.setConfig(config)
    ClixLogger.debug("Clix SDK initialized with environment: \(await environment.toString())")
  }
  /// Sets the user ID
  /// - Parameters:
  ///   - userId: User ID to set
  static func setUserId(_ userId: String) async {
    do {
      try await shared.deviceService.setProjectUserId(userId)
    } catch {
      ClixLogger.error("[Clix] Failed to set userId: \(error)")
    }
  }

  /// Removes the user ID
  static func removeUserId() async {
    do {
      try await shared.deviceService.removeProjectUserId()
    } catch {
      ClixLogger.error("[Clix] Failed to remove userId: \(error)")
    }
  }

  /// Sets a user property
  /// - Parameters:
  ///   - key: Property key
  ///   - value: Property value
  static func setUserProperty(_ key: String, value: Any) async {
    do {
      try await shared.deviceService.updateUserProperties([key: value])
    } catch {
      ClixLogger.error("[Clix] Failed to set user property: \(error)")
    }
  }

  /// Sets multiple user properties at once
  /// - Parameter userProperties: Dictionary of property keys and values
  static func setUserProperties(_ userProperties: [String: Any]) async {
    do {
      try await shared.deviceService.updateUserProperties(userProperties)
    } catch {
      ClixLogger.error("[Clix] Failed to set user properties: \(error)")
    }
  }

  /// Removes a user property
  /// - Parameter key: Property key to remove
  static func removeUserProperty(_ key: String) async {
    do {
      try await shared.deviceService.removeUserProperties([key])
    } catch {
      ClixLogger.error("[Clix] Failed to remove user property: \(error)")
    }
  }

  /// Removes multiple user properties
  /// - Parameter keys: Property keys to remove
  static func removeUserProperties(_ keys: [String]) async {
    do {
      try await shared.deviceService.removeUserProperties(keys)
    } catch {
      ClixLogger.error("[Clix] Failed to remove user properties: \(error)")
    }
  }

  /// Tracks an event
  /// - Parameters:
  ///   - name: Event name
  ///   - properties: Event properties
  static func trackEvent(_ name: String, properties: [String: Any?] = [:]) async {
    do {
      try await shared.eventService.trackEvent(name: name, properties: properties)
    } catch {
      ClixLogger.error("[Clix] Failed to track event: \(error)")
    }
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
}
