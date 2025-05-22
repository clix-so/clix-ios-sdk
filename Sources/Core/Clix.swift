import Foundation
import UIKit
import UserNotifications

/// Main class of Clix SDK
public actor Clix {
  // MARK: - Properties

  var config = ClixConfig()
  private let storageService = StorageService()
  internal lazy var tokenService = TokenService(storageService: storageService)
  internal lazy var userService = UserService(storageService: storageService, tokenService: tokenService)
  internal lazy var eventService = EventService()
  internal lazy var notificationService = NotificationService(storageService: storageService)

  private func setConfig(_ config: ClixConfig) {
    self.config = config
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
    await shared.setConfig(config)
  }

  /// Sets the user ID
  /// - Parameters:
  ///   - userId: User ID to set
  static func setUserId(_ userId: String) async throws {
    try await shared.userService.setUserId(userId)
  }

  /// Removes the user ID
  static func removeUserId() async throws {
    try await shared.userService.removeUserId()
  }

  /// Sets a user property
  /// - Parameters:
  ///   - key: Property key
  ///   - value: Property value
  static func setUserProperty(_ key: String, value: Any) async throws {
    try await shared.userService.setProperties([key: value])
  }

  /// Sets multiple user properties at once
  /// - Parameter userProperties: Dictionary of property keys and values
  static func setUserProperties(_ userProperties: [String: Any]) async throws {
    try await shared.userService.setProperties(userProperties)
  }

  /// Removes a user property
  /// - Parameter key: Property key to remove
  static func removeUserProperty(_ key: String) async throws {
    try await shared.userService.removeProperties([key])
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
}
