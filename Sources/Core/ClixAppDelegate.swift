import Foundation
import UIKit
import UserNotifications

/**
This class is designed as an optional base class to streamline the integration of Clix into your application. By inheriting from ClixAppDelegate in your AppDelegate, you gain automatic handling of Push Notification registration and device token management, simplifying the initial setup process for Clix's functionalities.

This class also provides a set of open helper functions that facilitate the handling of different Push Notification events such as delivery in the foreground, taps, and silent notifications. These helper methods offer a straightforward approach to customizing your app's response to notifications.

Key Features:
- Automatic registration for remote notifications, ensuring your app is promptly set up to receive and handle Push Notifications.
- Simplified device token management, with automatic storage of the device token for easier access and use.
- Customizable notification handling through open helper functions, allowing for bespoke responses to notification events.
- Automatic message status updates based on Push Notification interaction.
*/

@available(iOSApplicationExtension, unavailable)
open class ClixAppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  // MARK: - Launching

  /// Called when the application launches
  /// - NOTE: If overriding this function in your AppDelegate, make sure to call super to retain the default functionality.
  /// - Parameters:
  ///   - application: UIApplication instance
  ///   - launchOptions: Application launch options
  open func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self

    // Request permissions and automatically register for notifications
    requestAndRegisterForPushNotifications()

    // Check if app was launched from a notification tap
    if let launchOptions = launchOptions, let userInfo = launchOptions[.remoteNotification] as? [String: AnyObject] {
      ClixLogger.log(
        level: .debug,
        category: .pushNotification,
        message: "App launched from push notification"
      )
      pushNotificationTapped(userInfo: userInfo)
    }

    return true
  }

  // MARK: - Token Management

  /// Called when remote notification registration fails
  /// - Parameters:
  ///   - application: UIApplication instance
  ///   - error: The error that occurred
  open func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    ClixLogger.log(
      level: .error,
      category: .pushNotification,
      message: "Failed to register for remote notifications",
      error: error
    )
    Task {
      let properties: [String: AnyCodable] = [
        "error": AnyCodable(error.localizedDescription)
      ]
      try? await Clix.trackEvent(
        "push_registration_failed",
        properties: properties
      )
    }
  }

  /// Called when remote notification registration is successful
  /// - Parameters:
  ///   - application: UIApplication instance
  ///   - deviceToken: Device token data
  open func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Task {
      try? await handleDeviceToken(deviceToken)
    }
  }

  // MARK: - Notifications

  /// Called before a push notification is displayed
  /// - Parameters:
  ///   - center: UNUserNotificationCenter instance
  ///   - notification: Notification to be displayed
  ///   - completionHandler: Handler to set notification display options
  open func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    ClixLogger.log(
      level: .debug,
      category: .pushNotification,
      message: "Push notification delivered in foreground"
    )
    let presentationOptions = pushNotificationDeliveredInForeground(notification: notification)
    completionHandler(presentationOptions)
  }

  /// Handles user response to a push notification
  /// - Parameters:
  ///   - center: UNUserNotificationCenter instance
  ///   - response: User response
  ///   - completionHandler: Handler called after processing is complete
  open func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    ClixLogger.log(
      level: .debug,
      category: .pushNotification,
      message: "Push notification tapped"
    )
    pushNotificationTapped(userInfo: response.notification.request.content.userInfo)
    Task {
      try? await handleNotificationResponse(response)
      completionHandler()
    }
  }

  /// Called when a silent push notification is received
  /// - Parameters:
  ///   - application: UIApplication instance
  ///   - userInfo: Push notification information
  ///   - completionHandler: Handler to deliver background fetch results
  open func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    ClixLogger.log(
      level: .debug,
      category: .pushNotification,
      message: "Push notification delivered silently"
    )
    pushNotificationDeliveredSilently(userInfo: userInfo, completionHandler: completionHandler)
  }

  // MARK: - Helper Functions

  /// Requests push notification permissions and registers for notifications
  open func requestAndRegisterForPushNotifications() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if granted {
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }

      if let error = error {
        ClixLogger.log(
          level: .error,
          category: .pushNotification,
          message: "Failed to request notification authorization",
          error: error
        )
      }
    }
  }

  /// Extracts the message ID from notification payload
  /// - Parameter userInfo: Notification information
  /// - Returns: Message ID or nil
  open func getMessageId(userInfo: [AnyHashable: Any]) -> String? {
    userInfo["clix_message_id"] as? String
  }

  /// Handles push notification delivery in foreground
  /// - Parameter notification: Delivered notification
  /// - Returns: Notification presentation options
  open func pushNotificationDeliveredInForeground(notification: UNNotification) -> UNNotificationPresentationOptions {
    Task {
      try? await handleNotificationReceived(notification.request.content.userInfo)
    }

    guard #available(iOS 14.0, *) else {
      return [.alert, .sound, .badge]
    }
    return [.list, .banner, .sound, .badge]
  }

  /// Handles push notification tap
  /// - Parameter userInfo: Notification information
  open func pushNotificationTapped(userInfo: [AnyHashable: Any]) {
    if let messageId = getMessageId(userInfo: userInfo) {
      Task {
        let userInfoDict = convertHashableAnyToAnyCodable(userInfo)
        let properties: [String: AnyCodable] = [
          "message_id": AnyCodable(messageId),
          "payload": AnyCodable(userInfoDict),
        ]

        try? await Clix.trackEvent(
          "push_interacted",
          properties: properties
        )
      }
    }
  }

  /// Handles silent push notification delivery
  /// - Parameters:
  ///   - userInfo: Notification information
  ///   - completionHandler: Handler to deliver background fetch results
  open func pushNotificationDeliveredSilently(
    userInfo: [AnyHashable: Any],
    completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    Task {
      do {
        try await handleNotificationReceived(userInfo)
        completionHandler(.newData)
      } catch {
        completionHandler(.failed)
      }
    }
  }

  // MARK: - Internal Methods

  /// Handles the device token
  /// - Parameter token: Device token data
  open func handleDeviceToken(_ token: Data) async throws {
    let tokenString = Clix.shared.tokenService.convertTokenToString(token)
    Clix.shared.tokenService.saveToken(tokenString)
    let userId = Clix.shared.userService.getCurrentUser().userId
    try await Clix.shared.deviceService.registerDevice(token: tokenString, userId: userId)
  }

  /// Handles push notification reception
  /// - Parameter userInfo: Push notification information
  open func handleNotificationReceived(_ userInfo: [AnyHashable: Any]) async throws {
    let userInfoDict = convertHashableAnyToAnyCodable(userInfo)
    let properties: [String: AnyCodable] = [
      "payload": AnyCodable(userInfoDict)
    ]
    try await Clix.trackEvent("push_received", properties: properties)
  }

  /// Handles push notification response
  /// - Parameter response: Push notification response
  open func handleNotificationResponse(_ response: UNNotificationResponse) async throws {
    let userInfo = response.notification.request.content.userInfo
    let userInfoDict = convertHashableAnyToAnyCodable(userInfo)
    let properties: [String: AnyCodable] = [
      "payload": AnyCodable(userInfoDict)
    ]
    try await Clix.trackEvent(
      "push_opened",
      properties: properties
    )
  }

  // MARK: - Helper Methods

  /// Converts [AnyHashable: Any] to [String: Any] for AnyCodable compatibility
  /// - Parameter dictionary: Dictionary to convert
  /// - Returns: Converted dictionary
  private func convertHashableAnyToAnyCodable(_ dictionary: [AnyHashable: Any]) -> [String: Any] {
    var result: [String: Any] = [:]
    for (key, value) in dictionary {
      if let stringKey = key as? String {
        result[stringKey] = value
      }
    }
    return result
  }
}
