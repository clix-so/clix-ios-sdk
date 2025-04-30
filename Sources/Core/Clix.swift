import Foundation
import UIKit
import UserNotifications

/// Main class of Clix SDK
public class Clix {
  // MARK: - Properties

  var config: ClixConfig

  // MARK: - Services

  var userService: UserService
  var deviceService: DeviceService
  var eventService: EventService
  var tokenService: TokenService
  var notificationService: NotificationService

  // MARK: - Public Methods

  /// Initializes the Clix SDK
  /// - Parameters:
  ///   - apiKey: API key
  ///   - endpoint: Clix API endpoint URL (default: "https://api.clix.io")
  ///   - config: Clix SDK configuration
  public init(config: ClixConfig) async throws {
    ClixLogger.setLogLevel(config.logLevel)

    // Configure services
    self.config = config
    self.userService = UserService()
    self.deviceService = DeviceService()
    self.eventService = EventService()
    self.tokenService = TokenService()
    self.notificationService = NotificationService()
  }
}

public extension Clix {
  private static var shared: Clix?

  internal static func getShared() throws -> Clix {
    guard let shared = shared else {
      throw ClixError.notInitialized
    }
    return shared
  }

  /// Sets the user ID
  /// - Parameters:
  ///   - userId: User ID to set
  static func setUserId(_ userId: String) async throws {
    try getShared().userService.setUserId(userId)
    if let token = try getShared().tokenService.getCurrentToken() {
      try await getShared().deviceService.registerDevice(token: token, userId: userId)
    }
  }

  /// Removes the user ID
  static func removeUserId() async throws {
    try getShared().userService.removeUserId()
    if let token = try getShared().tokenService.getCurrentToken() {
      try await getShared().deviceService.registerDevice(token: token, userId: nil)
    }
  }

  /// Sets a user property
  /// - Parameters:
  ///   - key: Property key
  ///   - value: Property value
  static func setUserProperty(_ key: String, value: AnyCodable?) async throws {
    try await getShared().userService.setProperty(key, value: value)
  }

  /// Sets multiple user properties at once
  /// - Parameter userProperties: Dictionary of property keys and values
  static func setUserProperties(_ userProperties: [String: AnyCodable?]) async throws {
    try await getShared().userService.setProperties(userProperties)
  }

  /// Removes a user property
  /// - Parameter key: Property key to remove
  static func removeUserProperty(_ key: String) async throws {
    try await getShared().userService.removeProperty(key)
  }

  /// Tracks an event
  /// - Parameters:
  ///   - name: Event name
  ///   - properties: Event properties
  static func trackEvent(_ name: String, properties: [String: AnyCodable]? = nil) async throws {
    let userId = try getShared().userService.getCurrentUser().userId
    try await getShared().eventService.trackEvent(name: name, properties: properties)
  }

  /// Sets the logging level
  /// - Parameter level: Logging level to set
  static func setLogLevel(_ level: ClixLogLevel) {
    ClixLogger.setLogLevel(level)
  }
}
