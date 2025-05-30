import FirebaseCore
import FirebaseMessaging
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
open class ClixAppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
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
    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self

    // Request permissions and automatically register for notifications
    requestAndRegisterFornotifications()

    // Check if app was launched from a notification tap
    if let launchOptions = launchOptions, let payload = launchOptions[.remoteNotification] as? [String: AnyObject] {
      ClixLogger.debug("App launched from push notification")

      // Create a long-running task to ensure the notification event is fully processed
      // This fixes the issue of push notification tap events not being sent to the server
      // when the app is launched from a terminated state
      Task {
        // Add a small delay to ensure Clix is properly initialized
        try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

        // Handle the notification tap with proper async context
        // Create a copy of the userInfo to ensure thread safety across actor boundaries
        let userInfo = payload as NSDictionary as! [AnyHashable: Any]
        await Clix.shared.notificationService.handlePushTapped(userInfo: userInfo)
      }
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
    ClixLogger.error("Failed to register for remote notifications", error: error)
  }

  /// Called when remote notification registration is successful
  /// - Parameters:
  ///   - application: UIApplication instance
  ///   - deviceToken: Device token data
  open func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // 1. Set APNS token for Firebase Messaging
    // This allows FCM to use this APNS token to send notifications via APNS.
    Messaging.messaging().apnsToken = deviceToken
    ClixLogger.debug("APNS token set for Firebase Messaging.")

    // 2. Existing Clix logic for handling device token (now primarily for FCM token)
    // The explicit registration of the APNS token to the Clix server might become secondary
    // or unnecessary if the FCM token (derived/confirmed after setting APNS token)
    // becomes the primary token for Clix push services.
    // We will rely on the FCM token received via the MessagingDelegate for Clix server registration.
    // Task {
    //   try? await handleDeviceToken(deviceToken) // This originally handles APNS token
    // }
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
    ClixLogger.debug("Push notification delivered in foreground")
    let userInfo = notification.request.content.userInfo

    Clix.shared.notificationService.handlePushReceived(userInfo: notification.request.content.userInfo)

    // Prevent infinite notification loop for custom image notifications
    if userInfo["clix_image_handled"] as? Bool == true {
      let presentationOptions = notificationDeliveredInForeground(notification: notification)
      completionHandler(presentationOptions)
      return
    }

    var imageURLString: String? = nil
    // Extract image URL from various push payload formats
    if let directImage = userInfo["image_url"] as? String {
      imageURLString = directImage
    } else if let fcmOptions = userInfo["fcm_options"] as? [String: Any],
      let fcmImage = fcmOptions["image_url"] as? String
    {
      imageURLString = fcmImage
    } else if let fcmOptions = userInfo["fcm_options"] as? NSDictionary,
      let fcmImage = fcmOptions["image_url"] as? String
    {
      imageURLString = fcmImage
    }
    ClixLogger.debug("Push notification image URL: \(String(describing: imageURLString))")

    if let imageURLString = imageURLString, let url = URL(string: imageURLString) {
      downloadImageAndShowNotification(content: notification.request.content, imageURL: url)
      // Suppress the original notification: only show the custom image notification
      completionHandler([])
    } else {
      let presentationOptions = notificationDeliveredInForeground(notification: notification)
      completionHandler(presentationOptions)
    }
  }

  private func downloadImageAndShowNotification(content: UNNotificationContent, imageURL: URL) {
    let task = URLSession.shared.downloadTask(with: imageURL) { downloadedUrl, _, _ in
      guard let downloadedUrl = downloadedUrl else { return }
      let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
      let tmpFile = tmpDir.appendingPathComponent(imageURL.lastPathComponent)

      try? FileManager.default.moveItem(at: downloadedUrl, to: tmpFile)
      if let attachment = try? UNNotificationAttachment(identifier: "image", url: tmpFile, options: nil) {
        let newContent = content.mutableCopy() as! UNMutableNotificationContent
        newContent.attachments = [attachment]
        // Mark as handled to prevent recursion
        var newUserInfo = newContent.userInfo
        newUserInfo["clix_image_handled"] = true
        newContent.userInfo = newUserInfo
        // Use a stable identifier to avoid stacking duplicate notifications
        let userInfo = content.userInfo
        let identifier =
          (userInfo["gcm.message_id"] as? String) ?? (userInfo["message_id"] as? String) ?? UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: newContent, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
      }
    }
    task.resume()
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
    ClixLogger.debug("Push notification tapped")
    notificationTapped(userInfo: response.notification.request.content.userInfo)
    completionHandler()
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
    ClixLogger.debug("Push notification delivered silently")
    notificationDeliveredSilently(payload: payload, completionHandler: completionHandler)
  }

  // MARK: - Helper Functions

  /// Requests push notification permissions and registers for notifications
  open func requestAndRegisterFornotifications() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if granted {
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }

      if let error = error {
        ClixLogger.error("Failed to request notification authorization", error: error)
      }
    }
  }

  /// Handles push notification delivery in foreground
  /// - Parameter notification: Delivered notification
  /// - Returns: Notification presentation options
  open func notificationDeliveredInForeground(notification: UNNotification) -> UNNotificationPresentationOptions {
    guard #available(iOS 14.0, *) else {
      return [.alert, .sound, .badge]
    }
    return [.list, .banner, .sound, .badge]
  }

  /// Helper method to parse the Clix payload from push notification userInfo
  /// - Parameter userInfo: The notification's userInfo dictionary
  /// - Returns: Parsed Clix payload as [String: Any], or nil if parsing fails
  private func parseClixPayload(from userInfo: [AnyHashable: Any]) -> [String: Any]? {
    guard let clixValue = userInfo["clix"] else { return nil }
    ClixLogger.debug("Clix notification data: \(clixValue)")

    // 1. Try parsing as a dictionary directly
    if let clixData = clixValue as? [String: Any] {
      return clixData
    }
    // 2. Try parsing as a JSON string
    if let clixString = clixValue as? String {
      do {
        if let data = clixString.data(using: .utf8),
          let clixData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
          return clixData
        }
      } catch {
        ClixLogger.error("Failed to parse clix JSON data", error: error)
      }
    }
    return nil
  }

  /// Helper method to extract and open landing URL from push notification userInfo
  /// - Parameter userInfo: The notification's userInfo dictionary
  /// - Returns: True if landing URL was found and opened, false otherwise
  private func openLandingURLIfPresent(from userInfo: [AnyHashable: Any]) -> Bool {
    guard let clixData = parseClixPayload(from: userInfo),
      let landingURL = clixData["landing_url"] as? String,
      let url = URL(string: landingURL)
    else { return false }
    DispatchQueue.main.async {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    return true
  }

  /// Handles push notification tap
  /// - Parameter payload: Notification information
  open func notificationTapped(userInfo: [AnyHashable: Any]) {
    // Use Task to ensure async processing in actor context
    Task {
      // Create a copy of the userInfo to ensure thread safety across actor boundaries
      let isolatedUserInfo = userInfo as NSDictionary as! [AnyHashable: Any]
      await Clix.shared.notificationService.handlePushTapped(userInfo: isolatedUserInfo)

      // Try to open landing URL from the notification
      _ = openLandingURLIfPresent(from: isolatedUserInfo)
    }
  }

  /// Handles silent push notification delivery
  /// - Parameters:
  ///   - payload: Notification information
  ///   - completionHandler: Handler to deliver background fetch results
  open func notificationDeliveredSilently(
    payload: [AnyHashable: Any],
    completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    // Use Task to ensure async processing in actor context
    Task {
      // Create a copy of the payload to ensure thread safety across actor boundaries
      let isolatedPayload = payload as NSDictionary as! [AnyHashable: Any]
      await Clix.shared.notificationService.handlePushReceived(userInfo: isolatedPayload)
      completionHandler(.newData)
    }
  }

  // MARK: - Internal Methods

  /// Handles the device token
  /// - Parameter token: Device token data
  open func handleDeviceToken(_ token: Data) async throws {
    let tokenString = await Clix.shared.tokenService.convertTokenToString(token)
    await Clix.shared.tokenService.saveToken(tokenString)
    try await Clix.shared.deviceService.upsertToken(tokenString)
  }

  // MARK: - FCM Token Management

  public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let token = fcmToken else {
      ClixLogger.warn("FCM registration token is nil.")
      return
    }
    ClixLogger.debug("FCM registration token received: \(token)")
    Task {
      // Register the FCM token with Clix server. This is the primary token for pushes.
      try? await Clix.shared.deviceService.upsertToken(token, tokenType: "FCM")
    }
  }

  // MARK: - FCM Foreground Message Handling (Optional)

  open func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
    ClixLogger.debug("FCM push notification received (foreground)")

    // Use Task to ensure async processing in actor context
    Task {
      // Create a copy of the userInfo to ensure thread safety across actor boundaries
      let isolatedUserInfo = userInfo as NSDictionary as! [AnyHashable: Any]
      await Clix.shared.notificationService.handlePushReceived(userInfo: isolatedUserInfo)

      // Try to open landing URL from the notification
      _ = openLandingURLIfPresent(from: isolatedUserInfo)
    }
  }
}
