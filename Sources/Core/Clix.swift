import Foundation
import UIKit
import UserNotifications

/// Main class of Clix SDK
public class Clix {
  /// Singleton instance of Clix SDK
  static let shared = Clix()

  // MARK: - Properties

  private var config: ClixConfig?

  // MARK: - Services

  lazy var logger = ClixLogger()
  lazy var tokenService = TokenService()
  lazy var userService = UserService()
  lazy var eventService = EventService()
  lazy var notificationService = NotificationService()

  private init() {}

  // MARK: - Public Methods

  /// Initializes the Clix SDK
  /// - Parameters:
  ///   - apiKey: API key
  ///   - endpoint: Clix API endpoint URL (default: "https://api.clix.io")
  ///   - config: Clix SDK configuration
  public static func initialize(apiKey: String, endpoint: String, config: ClixConfig?) async throws {
    shared.logger.setLogLevel(config?.logLevel ?? .info)

    // Configure services
    UserAPIService.shared.configure(apiKey: apiKey, endpoint: endpoint)
    EventAPIService.shared.configure(apiKey: apiKey, endpoint: endpoint)

    // Initialize token service
    try await shared.tokenService.initialize()

    // Request notification permission
    let granted = try await UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .sound, .badge])
    if granted {
      await MainActor.run {
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }

  /// Sets the user ID
  /// - Parameters:
  ///   - userId: User ID to set
  public static func setUserId(_ userId: String) async throws {
    shared.userService.setUserId(userId)
    if let token = shared.tokenService.getCurrentToken() {
      try await shared.userService.registerDevice(token: token, userId: userId)
    }
  }

  /// Removes the user ID
  public static func removeUserId() async throws {
    shared.userService.removeUserId()
    if let token = shared.tokenService.getCurrentToken() {
      try await shared.userService.registerDevice(token: token, userId: nil)
    }
  }

  /// Sets a user attribute
  /// - Parameters:
  ///   - key: Attribute key
  ///   - value: Attribute value
  public static func setAttribute(_ key: String, value: AnyCodable?) async throws {
    try await shared.userService.setAttribute(key, value: value)
  }

  /// Sets multiple user attributes at once
  /// - Parameter userAttributes: Dictionary of attribute keys and values
  public static func setAttributes(_ userAttributes: [String: AnyCodable?]) async throws {
    try await shared.userService.setAttributes(userAttributes)
  }

  /// Removes a user attribute
  /// - Parameter key: Attribute key to remove
  public static func removeAttribute(_ key: String) async throws {
    try await shared.userService.removeAttribute(key)
  }

  /// Tracks an event
  /// - Parameters:
  ///   - name: Event name
  ///   - properties: Event properties
  public static func trackEvent(_ name: String, properties: [String: AnyCodable]? = nil) async throws {
    let userId = shared.userService.getCurrentUser().userId
    try await shared.eventService.trackEvent(name: name, properties: properties, userId: userId)
  }

  /// Sets the logging level
  /// - Parameter level: Logging level to set
  public static func setLogLevel(_ level: ClixLogLevel) {
    shared.logger.setLogLevel(level)
  }

  /// Resets the Clix SDK to its initial state
  public static func reset() {
    shared.config = nil
    shared.tokenService.reset()
    shared.userService.reset()
    shared.notificationService.reset()
    shared.eventService.reset()
  }
}
