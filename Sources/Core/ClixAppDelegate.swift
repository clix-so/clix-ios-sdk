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
    if let launchOptions = launchOptions, let payload = launchOptions[.remoteNotification] as? [String: AnyObject] {
      ClixLogger.log(
        level: .debug,
        category: .pushNotification,
        message: "App launched from push notification"
      )
      pushNotificationTapped(payload: payload)
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
      try? await Clix.trackEvent(
        "push_registration_failed",
        properties: [
          "error": error.localizedDescription
        ]
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
    pushNotificationTapped(payload: response.notification.request.content.userInfo)
    Task {
      try? await handleNotificationResponse(response)
      completionHandler()
    }
  }

  /// Called when a silent push notification is received
  /// - Parameters:
  ///   - application: UIApplication instance
  ///   - payload: Push notification information
  ///   - completionHandler: Handler to deliver background fetch results
  open func application(
    _ application: UIApplication,
    didReceiveRemoteNotification payload: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    ClixLogger.log(
      level: .debug,
      category: .pushNotification,
      message: "Push notification delivered silently"
    )
    pushNotificationDeliveredSilently(payload: payload, completionHandler: completionHandler)
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
  /// - Parameter payload: Notification information
  /// - Returns: Message ID or nil
  open func getMessageId(payload: [AnyHashable: Any]) -> String? {
    payload["message_id"] as? String
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
  /// - Parameter payload: Notification information
  open func pushNotificationTapped(payload: [AnyHashable: Any]) {
    if let messageId = getMessageId(payload: payload) {
      Task {
        try? await Clix.trackEvent(
          "push_interacted",
          properties: [
            "message_id": messageId,
            "payload": payload,
          ]
        )
      }
    }
  }

  /// Handles silent push notification delivery
  /// - Parameters:
  ///   - payload: Notification information
  ///   - completionHandler: Handler to deliver background fetch results
  open func pushNotificationDeliveredSilently(
    payload: [AnyHashable: Any],
    completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    Task {
      do {
        try await handleNotificationReceived(payload)
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
    let tokenString = await Clix.shared.tokenService.convertTokenToString(token)
    await Clix.shared.tokenService.saveToken(tokenString)
    try await Clix.shared.userService.registerDevice(token: tokenString)
  }

  /// Handles push notification reception
  /// - Parameter payload: Push notification information
  open func handleNotificationReceived(_ payload: [AnyHashable: Any]) async throws {
    try await Clix.trackEvent(
      "push_received",
      properties: [
        "payload": payload
      ]
    )
  }

  /// Handles push notification response
  /// - Parameter response: Push notification response
  open func handleNotificationResponse(_ response: UNNotificationResponse) async throws {
    let payload = response.notification.request.content.userInfo
    try await Clix.trackEvent(
      "push_opened",
      properties: [
        "payload": payload
      ]
    )
  }
}
