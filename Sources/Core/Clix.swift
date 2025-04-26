import Foundation
import UIKit
import UserNotifications

/// Main class of Clix SDK
public class Clix {
  /// Singleton instance of Clix SDK
  public static let shared = Clix()

  // MARK: - Properties

  private var config: ClixConfig?
  private var userId: String?

  // MARK: - Services

  private lazy var logger = ClixLogger()
  private lazy var tokenService = ClixTokenService()
  private lazy var userService = ClixUserService()
  private lazy var eventService = ClixEventService()
  private lazy var networkService = ClixNetworkService()
  private lazy var notificationService = ClixNotificationService()

  private init() {}

  // MARK: - Public Methods

  /// Initializes the Clix SDK
  /// - Parameters:
  ///   - apiKey: API key
  ///   - endpoint: Clix API endpoint URL (default: "https://api.clix.io")
  ///   - config: Clix SDK configuration
  public func initialize(apiKey: String, endpoint: String, config: ClixConfig?) async throws {
    logger.setLogLevel(config?.loggingLevel ?? .info)

    // Configure network service
    networkService.configure(apiKey: apiKey, endpoint: endpoint)

    // Initialize token service
    try await tokenService.initialize()

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
  public func setUserId(_ userId: String) async throws {
    self.userId = userId
    if let token = tokenService.getCurrentToken() {
      try await userService.registerDevice(token: token, userId: userId)
    }
  }

  /// Removes the user ID
  public func removeUserId() async throws {
    userId = nil
    if let token = tokenService.getCurrentToken() {
      try await userService.registerDevice(token: token, userId: nil)
    }
  }

  /// Sets a user attribute
  /// - Parameters:
  ///   - key: Attribute key
  ///   - value: Attribute value
  public func setAttribute(_ key: String, value: Any) async throws {
    try await userService.setAttribute(key, value: value)
  }

  /// Tracks an event
  /// - Parameters:
  ///   - name: Event name
  ///   - properties: Event properties
  public func trackEvent(_ name: String, properties: [String: Any]? = nil) async throws {
    try await eventService.trackEvent(name: name, properties: properties, userId: userId)
  }

  /// Resets the Clix SDK to its initial state
  public func reset() {
    config = nil
    userId = nil
    tokenService.reset()
    userService.reset()
    notificationService.reset()
    eventService.reset()
  }

  // MARK: - Internal Methods

  /// Handles the device token
  /// - Parameters:
  ///   - token: Device token data
  func handleDeviceToken(_ token: Data) async throws {
    let tokenString = tokenService.convertTokenToString(token)
    tokenService.setCurrentToken(tokenString)
    try await userService.registerDevice(token: tokenString, userId: userId)
  }

  /// Handles push notification reception
  /// - Parameters:
  ///   - userInfo: Push notification information
  func handleNotificationReceived(_ userInfo: [AnyHashable: Any]) async throws {
    try await trackEvent("push_received", properties: ["payload": userInfo])
  }

  /// Handles push notification response
  /// - Parameters:
  ///   - response: Push notification response
  func handleNotificationResponse(_ response: UNNotificationResponse) async throws {
    try await trackEvent(
      "push_opened",
      properties: ["payload": response.notification.request.content.userInfo]
    )
  }

  // MARK: - Public Methods

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
  public func application(
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
  public func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    logger.log(
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
  public func userNotificationCenter(
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
  public func userNotificationCenter(
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
