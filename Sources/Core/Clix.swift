import Foundation
import UIKit
import UserNotifications

/// Main class of Clix SDK
public class Clix {
  /// Singleton instance of Clix SDK
  private static let shared = Clix()

  // MARK: - Properties

  private var config: ClixConfig?

  // MARK: - Services

  private lazy var logger = ClixLogger()
  private lazy var tokenService = TokenService()
  private lazy var userService = UserService()
  private lazy var eventService = EventService()
  private lazy var networkService = NetworkService()
  private lazy var notificationService = NotificationService()

  private init() {}

  // MARK: - Public Methods

  /// Initializes the Clix SDK
  /// - Parameters:
  ///   - apiKey: API key
  ///   - endpoint: Clix API endpoint URL (default: "https://api.clix.io")
  ///   - config: Clix SDK configuration
  public static func initialize(apiKey: String, endpoint: String, config: ClixConfig?) async throws {
    shared.logger.setLogLevel(config?.logLevel ?? .info)

    // Configure network service
    shared.networkService.configure(apiKey: apiKey, endpoint: endpoint)

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

  /// Gets the current user
  /// - Returns: Current ClixUser
  public static func getCurrentUser() -> ClixUser {
    shared.userService.getCurrentUser()
  }

  /// Sets a user attribute
  /// - Parameters:
  ///   - key: Attribute key
  ///   - value: Attribute value
  public static func setAttribute(_ key: String, value: Any?) async throws {
    try await shared.userService.setAttribute(key, value: value)
  }

  /// Sets multiple user attributes at once
  /// - Parameter userAttributes: Dictionary of attribute keys and values
  public static func setAttributes(_ userAttributes: [String: Any?]) async throws {
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
  public static func trackEvent(_ name: String, properties: [String: Any]? = nil) async throws {
    let userId = shared.userService.getCurrentUser().userId
    try await shared.eventService.trackEvent(name: name, properties: properties, userId: userId)
  }

  /// Resets the Clix SDK to its initial state
  public static func reset() {
    shared.config = nil
    shared.tokenService.reset()
    shared.userService.reset()
    shared.notificationService.reset()
    shared.eventService.reset()
  }

  // MARK: - Internal Methods

  /// Handles the device token
  /// - Parameters:
  ///   - token: Device token data
  static func handleDeviceToken(_ token: Data) async throws {
    let tokenString = shared.tokenService.convertTokenToString(token)
    shared.tokenService.setCurrentToken(tokenString)
    let userId = shared.userService.getCurrentUser().userId
    try await shared.userService.registerDevice(token: tokenString, userId: userId)
  }

  /// Handles push notification reception
  /// - Parameters:
  ///   - userInfo: Push notification information
  static func handleNotificationReceived(_ userInfo: [AnyHashable: Any]) async throws {
    try await trackEvent("push_received", properties: ["payload": userInfo])
  }

  /// Handles push notification response
  /// - Parameters:
  ///   - response: Push notification response
  static func handleNotificationResponse(_ response: UNNotificationResponse) async throws {
    try await trackEvent(
      "push_opened",
      properties: ["payload": response.notification.request.content.userInfo]
    )
  }

  /// Sets the logging level
  /// - Parameter level: Logging level to set
  public static func setLogLevel(_ level: ClixLogLevel) {
    shared.logger.setLogLevel(level)
  }

  /// Returns the current device token
  /// - Returns: Current device token string
  public static func getCurrentToken() -> String? {
    shared.tokenService.getCurrentToken()
  }

  /// Returns the list of previous device tokens
  /// - Returns: Array of previous device token strings
  public static func getPreviousTokens() -> [String] {
    shared.tokenService.getPreviousTokens()
  }

  // MARK: - UIApplicationDelegate Methods

  /// Called when remote notification registration is successful
  /// - Parameters:
  ///   - application: UIApplication instance
  ///   - deviceToken: Device token data
  public static func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Task {
      try? await handleDeviceToken(deviceToken)
    }
  }

  /// Called when remote notification registration fails
  /// - Parameters:
  ///   - application: UIApplication instance
  ///   - error: Error that occurred
  public static func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    shared.logger.log(
      level: .error,
      category: .pushNotification,
      message: "Failed to register for remote notifications",
      error: error
    )
    Task {
      try? await trackEvent(
        "push_registration_failed",
        properties: ["error": error.localizedDescription]
      )
    }
  }

  // MARK: - UNUserNotificationCenterDelegate Methods

  /// Called before a push notification is displayed
  /// - Parameters:
  ///   - center: UNUserNotificationCenter instance
  ///   - notification: Notification to be displayed
  ///   - completionHandler: Handler to set notification display options
  public static func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
      Void
  ) {
    completionHandler([.alert, .sound, .badge])
  }

  /// Handles user response to a push notification
  /// - Parameters:
  ///   - center: UNUserNotificationCenter instance
  ///   - response: User response
  ///   - completionHandler: Handler called after processing is complete
  public static func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    Task {
      try? await handleNotificationResponse(response)
      completionHandler()
    }
  }
}
