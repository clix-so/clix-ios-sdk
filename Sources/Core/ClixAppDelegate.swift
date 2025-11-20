import FirebaseCore
import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

/// Base AppDelegate class for Clix SDK integration.
@available(iOSApplicationExtension, unavailable)
open class ClixAppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  // MARK: - Override Points
  /// Whether to request notification permission automatically.
  /// Override to delay the permission prompt (e.g., show onboarding first).
  open var autoRequestPermission: Bool { false }

  @available(*, deprecated, renamed: "autoRequestPermission")
  open var autoRequestAuthorizationOnLaunch: Bool { false }

  /// Whether the SDK should automatically handle landing URLs when a notification is tapped.
  /// Override to disable auto-handling and handle routing yourself.
  open var autoHandleLandingURL: Bool { true }

  @available(*, deprecated, renamed: "autoHandleLandingURL")
  open var autoOpenLandingOnTap: Bool { autoHandleLandingURL }

  /// Optional hook to provide custom foreground presentation options.
  /// Return a value to override; return nil to use SDK's default handling.
  open func willPresentOptions(for notification: UNNotification) -> UNNotificationPresentationOptions? { nil }

  // MARK: - Private Helpers

  private var shouldAutoRequestPermission: Bool {
    autoRequestPermission || autoRequestAuthorizationOnLaunch
  }

  // MARK: - UIApplicationDelegate

  open func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self

    // Apply configuration from override points
    Clix.Notification.configure(
      autoRequestPermission: shouldAutoRequestPermission,
      autoHandleLandingURL: autoHandleLandingURL
    )
    Clix.Notification.handleLaunchOptions(launchOptions)
    return true
  }

  open func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Clix.Notification.setApnsToken(deviceToken)
  }

  open func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    ClixLogger.error("Failed to register for remote notifications", error: error)
  }

  open func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
    Clix.Notification.handleForegroundNotification(userInfo)
  }

  open func application(
    _ application: UIApplication,
    didReceiveRemoteNotification payload: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    Clix.Notification.handleBackgroundNotification(payload, completionHandler: completionHandler)
  }

  // MARK: - UNUserNotificationCenterDelegate

  open func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if let custom = willPresentOptions(for: notification) {
      completionHandler(custom)
      return
    }
    Clix.Notification.handleWillPresent(notification: notification, completionHandler: completionHandler)
  }

  open func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    Clix.Notification.handleDidReceive(response: response, completionHandler: completionHandler)
  }
}
