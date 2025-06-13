@preconcurrency import Foundation
import UIKit
import UserNotifications

/**
 * Clix SDK - Main Entry Point
 *
 * The Clix class serves as the primary entry point for the Clix iOS SDK, providing
 * a comprehensive suite of tools for user analytics, event tracking, push notifications,
 * and device management.
 *
 * Key Features:
 * - User identification and property management
 * - Event tracking and analytics
 * - Push notification handling and rich media support
 * - Device management and token services
 * - Persistent storage with UserDefaults integration
 * - Asynchronous and synchronous API patterns
 *
 * Architecture:
 * The SDK follows a modular architecture with distinct service layers:
 * - StorageService: Persistent data management
 * - TokenService: Authentication and token management
 * - EventService: Event tracking and analytics
 * - DeviceService: Device registration and user property management
 * - NotificationService: Push notification processing
 *
 * Initialization:
 * The SDK supports both async and sync initialization patterns:
 * ```swift
 * // Recommended async approach
 * let config = ClixConfig(projectId: "your-project-id")
 * await Clix.initialize(config: config)
 *
 * // Synchronous approach (background initialization)
 * Clix.initialize(config: config)
 * ```
 *
 * Usage Examples:
 * ```swift
 * // Set user identification
 * try await Clix.setUserId("user123")
 *
 * // Set user properties
 * try await Clix.setUserProperty("subscription", value: "premium")
 * try await Clix.setUserProperties(["age": 25, "city": "Seoul"])
 *
 * // Remove user data
 * try await Clix.removeUserId()
 * try await Clix.removeUserProperty("subscription")
 *
 * // Get device information
 * let deviceId = await Clix.getDeviceId()
 * let pushToken = await Clix.getPushToken()
 * ```
 *
 * Thread Safety:
 * - All public APIs are thread-safe
 * - InitCoordinator manages initialization synchronization
 * - Services handle concurrent access appropriately
 *
 * Requirements:
 * - iOS 14+ deployment target
 * - Swift 5.5+ for async/await support
 * - UserNotifications framework for push notification features
 *
 * Note: The SDK uses a singleton pattern with lazy service initialization.
 * All services are initialized during the first `initialize(config:)` call.
 */
public final class Clix {
  // MARK: - Type Properties
  static let version = ClixVersion.current
  static let shared = Clix()

  // MARK: - Storage Keys
  private static let configKey = "clix_config"

  // MARK: - Instance Properties
  var environment: ClixEnvironment?
  var storageService: StorageService?
  var tokenService: TokenService?
  var eventService: EventService?
  var deviceService: DeviceService?
  var notificationService: NotificationService?

  // MARK: - Initialization Coordinator
  private let initCoordinator = InitCoordinator()

  private init() {}

  // MARK: - Private Methods
  private func setConfig(_ config: ClixConfig) {
    self.storageService = StorageService(projectId: config.projectId)
    guard let storageService = self.storageService else {
      ClixLogger.error("Failed to initialize StorageService")
      return
    }

    self.tokenService = TokenService(storageService: storageService)
    guard let tokenService = self.tokenService else {
      ClixLogger.error("Failed to initialize TokenService")
      return
    }

    self.eventService = EventService()
    guard let eventService = self.eventService else {
      ClixLogger.error("Failed to initialize EventService")
      return
    }

    self.deviceService = DeviceService(storageService: storageService, tokenService: tokenService)
    self.notificationService = NotificationService(storageService: storageService, eventService: eventService)
  }

  // MARK: - Internal Methods
  func setEnvironment(_ env: ClixEnvironment) {
    self.environment = env
  }

  // MARK: - Lazy Field Access Helper
  func get<T>(_ keyPath: KeyPath<Clix, T?>) throws -> T {
    guard let service = self[keyPath: keyPath] else {
      let fieldName = String(describing: T.self)
      ClixLogger.error("\(fieldName) not available")
      throw ClixError.notInitialized
    }
    return service
  }

  // MARK: - Async Field Access Helper with Initialization Wait
  func getWithWait<T>(_ keyPath: KeyPath<Clix, T?>) async throws -> T {
    await initCoordinator.waitForInitialization()
    return try get(keyPath)
  }

  // MARK: - Public Static API

  /// Initialize the Clix SDK (async version - recommended)
  ///
  /// This async version ensures initialization completes before returning,
  /// Use this when you can await the initialization in an async context.
  ///
  /// - Parameters:
  ///   - config: ClixConfig SDK configuration
  /// - Note: For backwards compatibility, a synchronous version is also available,
  ///         but this async version is recommended for better initialization control.
  public static func initialize(config: ClixConfig) async {
    do {
      ClixLogger.setLogLevel(config.logLevel)
      shared.setConfig(config)
      let deviceId = try await shared.get(\.deviceService).getCurrentDeviceId()
      let token = try await shared.get(\.tokenService).getCurrentToken()
      let device = await DeviceService.createDevice(deviceId: deviceId, token: token)
      let environment = ClixEnvironment(config: config, device: device)
      shared.setEnvironment(environment)

      try await shared.get(\.storageService).set(Self.configKey, config)

      ClixLogger.debug("Clix SDK initialized with environment: \(environment.toString())")

      await shared.initCoordinator.completeInitialization()
    } catch {
      ClixLogger.error("Failed to initialize Clix SDK: \(error)")
    }
  }

  /// Initialize the Clix SDK (synchronous version)
  ///
  /// This synchronous version returns immediately while initialization continues in the background.
  /// Consider using the async version for guaranteed initialization completion.
  ///
  /// - Parameters:
  ///   - config: ClixConfig SDK configuration
  /// - Note: An async version is available that ensures initialization completes before returning.
  ///         Use `await Clix.initialize(config:)` for better control over initialization timing.
  public static func initialize(config: ClixConfig) {
    Task {
      await initialize(config: config)
    }
  }

  static func initialize(projectId: String) async throws {
    let storageService = StorageService(projectId: projectId)
    let config: ClixConfig? = await storageService.get(Self.configKey)
    guard let config = config else {
      ClixLogger.error("Failed to initialize Clix SDK: Project ID not found in UserDefaults config")
      throw ClixError.notInitialized
    }
    await initialize(config: config)
  }

  /// Sets the user ID (async version - recommended)
  ///
  /// This async version ensures the operation completes before returning.
  /// Use this when you can await the operation in an async context.
  ///
  /// - Parameters:
  ///   - userId: User ID to set
  /// - Throws: ClixError if the operation fails
  public static func setUserId(_ userId: String) async throws {
    await shared.initCoordinator.waitForInitialization()
    try await shared.get(\.deviceService).setProjectUserId(userId)
  }

  /// Sets the user ID (synchronous version)
  ///
  /// This synchronous version returns immediately while the operation continues in the background.
  /// Consider using the async version for guaranteed operation completion.
  ///
  /// - Parameters:
  ///   - userId: User ID to set
  /// - Note: An async version is available that ensures the operation completes before returning.
  ///         Use `try await Clix.setUserId(_:)` for better control over operation timing.
  public static func setUserId(_ userId: String) {
    Task.detached(priority: .userInitiated) {
      do {
        try await setUserId(userId)
      } catch {
        ClixLogger.error("Failed to set userId: \(error)")
      }
    }
  }

  /// Removes the user ID (async version - recommended)
  ///
  /// This async version ensures the operation completes before returning.
  /// Use this when you can await the operation in an async context.
  ///
  /// - Throws: ClixError if the operation fails
  public static func removeUserId() async throws {
    await shared.initCoordinator.waitForInitialization()
    try await shared.get(\.deviceService).removeProjectUserId()
  }

  /// Removes the user ID (synchronous version)
  ///
  /// This synchronous version returns immediately while the operation continues in the background.
  /// Consider using the async version for guaranteed operation completion.
  ///
  /// - Note: An async version is available that ensures the operation completes before returning.
  ///         Use `try await Clix.removeUserId()` for better control over operation timing.
  public static func removeUserId() {
    Task.detached(priority: .userInitiated) {
      do {
        try await removeUserId()
      } catch {
        ClixLogger.error("Failed to remove userId: \(error)")
      }
    }
  }

  /// Sets a user property (async version - recommended)
  ///
  /// This async version ensures the operation completes before returning.
  /// Use this when you can await the operation in an async context.
  ///
  /// - Parameters:
  ///   - key: Property key
  ///   - value: Property value
  /// - Throws: ClixError if the operation fails
  public static func setUserProperty(_ key: String, value: Any) async throws {
    await shared.initCoordinator.waitForInitialization()
    try await shared.get(\.deviceService).updateUserProperties([key: value])
  }

  /// Sets a user property (synchronous version)
  ///
  /// This synchronous version returns immediately while the operation continues in the background.
  /// Consider using the async version for guaranteed operation completion.
  ///
  /// - Parameters:
  ///   - key: Property key
  ///   - value: Property value
  /// - Note: An async version is available that ensures the operation completes before returning.
  ///         Use `try await Clix.setUserProperty(_:value:)` for better control over operation timing.
  public static func setUserProperty(_ key: String, value: Any) {
    Task.detached(priority: .userInitiated) {
      do {
        try await setUserProperty(key, value: value)
      } catch {
        ClixLogger.error("Failed to set user property: \(error)")
      }
    }
  }

  /// Sets multiple user properties at once (async version - recommended)
  ///
  /// This async version ensures the operation completes before returning.
  /// Use this when you can await the operation in an async context.
  ///
  /// - Parameter userProperties: Dictionary of property keys and values
  /// - Throws: ClixError if the operation fails
  public static func setUserProperties(_ userProperties: [String: Any]) async throws {
    await shared.initCoordinator.waitForInitialization()
    try await shared.get(\.deviceService).updateUserProperties(userProperties)
  }

  /// Sets multiple user properties at once (synchronous version)
  ///
  /// This synchronous version returns immediately while the operation continues in the background.
  /// Consider using the async version for guaranteed operation completion.
  ///
  /// - Parameter userProperties: Dictionary of property keys and values
  /// - Note: An async version is available that ensures the operation completes before returning.
  ///         Use `try await Clix.setUserProperties(_:)` for better control over operation timing.
  public static func setUserProperties(_ userProperties: [String: Any]) {
    Task.detached(priority: .userInitiated) {
      do {
        try await setUserProperties(userProperties)
      } catch {
        ClixLogger.error("Failed to set user properties: \(error)")
      }
    }
  }

  /// Removes a user property (async version - recommended)
  ///
  /// This async version ensures the operation completes before returning.
  /// Use this when you can await the operation in an async context.
  ///
  /// - Parameter key: Property key to remove
  /// - Throws: ClixError if the operation fails
  public static func removeUserProperty(_ key: String) async throws {
    await shared.initCoordinator.waitForInitialization()
    try await shared.get(\.deviceService).removeUserProperties([key])
  }

  /// Removes a user property (synchronous version)
  ///
  /// This synchronous version returns immediately while the operation continues in the background.
  /// Consider using the async version for guaranteed operation completion.
  ///
  /// - Parameter key: Property key to remove
  /// - Note: An async version is available that ensures the operation completes before returning.
  ///         Use `try await Clix.removeUserProperty(_:)` for better control over operation timing.
  public static func removeUserProperty(_ key: String) {
    Task.detached(priority: .userInitiated) {
      do {
        try await removeUserProperty(key)
      } catch {
        ClixLogger.error("Failed to remove user property: \(error)")
      }
    }
  }

  /// Removes multiple user properties (async version - recommended)
  ///
  /// This async version ensures the operation completes before returning.
  /// Use this when you can await the operation in an async context.
  ///
  /// - Parameter keys: Property keys to remove
  /// - Throws: ClixError if the operation fails
  public static func removeUserProperties(_ keys: [String]) async throws {
    await shared.initCoordinator.waitForInitialization()
    try await shared.get(\.deviceService).removeUserProperties(keys)
  }

  /// Removes multiple user properties (synchronous version)
  ///
  /// This synchronous version returns immediately while the operation continues in the background.
  /// Consider using the async version for guaranteed operation completion.
  ///
  /// - Parameter keys: Property keys to remove
  /// - Note: An async version is available that ensures the operation completes before returning.
  ///         Use `try await Clix.removeUserProperties(_:)` for better control over operation timing.
  public static func removeUserProperties(_ keys: [String]) {
    Task.detached(priority: .userInitiated) {
      do {
        try await removeUserProperties(keys)
      } catch {
        ClixLogger.error("Failed to remove user properties: \(error)")
      }
    }
  }

  /// Sets the logging level
  /// - Parameter level: Logging level to set
  public static func setLogLevel(_ level: ClixLogLevel) {
    ClixLogger.setLogLevel(level)
  }

  /// Gets the device ID
  /// - Returns: Device ID
  public static func getDeviceId() -> String? {
    if let environment = try? shared.get(\.environment) {
      return environment.getDevice().id
    }

    if Thread.isMainThread {
      ClixLogger.warn(
        "getDeviceId() called on main thread before initialization complete. "
          + "Returning nil to avoid freeze. Consider using async version: await Clix.getDeviceId()"
      )
      return nil
    }

    return shared.initCoordinator.waitAndGet {
      (try? shared.get(\.environment))?.getDevice().id
    }
  }

  /// Gets the device ID
  /// - Returns: Device ID
  public static func getDeviceId() async -> String? {
    await shared.initCoordinator.waitForInitialization()
    return (try? shared.get(\.environment))?.getDevice().id
  }

  /// Gets the push token
  /// - Returns: Push token
  public static func getPushToken() -> String? {
    if let environment = try? shared.get(\.environment) {
      return environment.getDevice().pushToken
    }

    if Thread.isMainThread {
      ClixLogger.warn(
        "getPushToken() called on main thread before initialization complete. "
          + "Returning nil to avoid freeze. Consider using async version: await Clix.getPushToken()"
      )
      return nil
    }

    return shared.initCoordinator.waitAndGet {
      (try? shared.get(\.environment))?.getDevice().pushToken
    }
  }

  /// Gets the push token
  /// - Returns: Push token
  public static func getPushToken() async -> String? {
    await shared.initCoordinator.waitForInitialization()
    return (try? shared.get(\.environment))?.getDevice().pushToken
  }

  // MARK: - Internal Static API

  /// Tracks an event
  /// - Parameters:
  ///   - name: Event name
  ///   - properties: Event properties
  ///   - messageId: Optional message ID to include in properties
  static func trackEvent(_ name: String, properties: [String: Any?] = [:], messageId: String? = nil) {
    Task.detached(priority: .userInitiated) {
      await shared.initCoordinator.waitForInitialization()

      do {
        let eventService = try shared.get(\.eventService)
        var eventProperties = properties
        if let messageId = messageId {
          eventProperties["message_id"] = messageId
        }
        try await eventService.trackEvent(name: name, properties: eventProperties, messageId: messageId)
      } catch {
        ClixLogger.error("Failed to track event: \(error)")
      }
    }
  }

  private actor InitCoordinator {
    private var isInitialized = false
    private var pendingContinuations: [CheckedContinuation<Void, Never>] = []

    func waitForInitialization() async {
      if isInitialized {
        return
      }

      await withCheckedContinuation { continuation in
        pendingContinuations.append(continuation)
      }
    }

    func completeInitialization() {
      isInitialized = true
      let continuations = pendingContinuations
      pendingContinuations.removeAll()

      for continuation in continuations {
        continuation.resume()
      }
    }

    nonisolated func waitAndGet<T>(_ getter: @escaping () -> T?) -> T? {
      let semaphore = DispatchSemaphore(value: 0)
      var result: T?

      Task {
        await waitForInitialization()
        result = getter()
        semaphore.signal()
      }

      let timeout = DispatchTime.now() + .milliseconds(500)
      guard semaphore.wait(timeout: timeout) == .success else {
        ClixLogger.warn(
          "Timeout waiting for Clix initialization. Consider calling these methods after initialization is complete."
        )
        return nil
      }
      return result
    }
  }
}
