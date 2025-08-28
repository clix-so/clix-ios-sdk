import FirebaseCore
import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

@available(iOSApplicationExtension, unavailable)
open class ClixAppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
  private var pendingURL: URL?

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  open func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self

    requestAndRegisterFornotifications()

    setupAppStateNotifications()

    if let launchOptions = launchOptions, let payload = launchOptions[.remoteNotification] as? [String: AnyObject] {
      ClixLogger.debug("App launched from push notification")
      handleNotificationTapped(userInfo: payload)
    }

    return true
  }

  open func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    ClixLogger.error("Failed to register for remote notifications", error: error)
  }

  open func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    ClixLogger.debug("APNS token set for Firebase Messaging.")
  }

  open func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    ClixLogger.debug("Push notification delivered in foreground")
    let userInfo = notification.request.content.userInfo

    handleNotificationReceived(userInfo: userInfo)

    if userInfo["clix_image_handled"] as? Bool == true {
      let presentationOptions = notificationDeliveredInForeground(notification: notification)
      completionHandler(presentationOptions)
      return
    }

    var imageURLString: String?

    if let clixData = parseClixPayload(from: userInfo),
      let clixImageUrl = clixData["image_url"] as? String
    {
      imageURLString = clixImageUrl
      ClixLogger.debug("Found image_url in clix data: \(clixImageUrl)")
    } else if let directImage = userInfo["image_url"] as? String {
      imageURLString = directImage
      ClixLogger.debug("Found image_url in userInfo: \(directImage)")
    } else if let fcmOptions = userInfo["fcm_options"] as? [String: Any],
      let fcmImage = fcmOptions["image_url"] as? String
    {
      imageURLString = fcmImage
      ClixLogger.debug("Found image_url in fcm_options: \(fcmImage)")
    } else if let fcmOptions = userInfo["fcm_options"] as? NSDictionary,
      let fcmImage = fcmOptions["image_url"] as? String
    {
      imageURLString = fcmImage
      ClixLogger.debug("Found image_url in fcm_options dictionary: \(fcmImage)")
    }

    ClixLogger.debug("Push notification image URL: \(String(describing: imageURLString))")

    if let imageURLString = imageURLString, let url = URL(string: imageURLString) {
      downloadImageAndShowNotification(content: notification.request.content, imageURL: url)
      completionHandler([])
    } else {
      let presentationOptions = notificationDeliveredInForeground(notification: notification)
      completionHandler(presentationOptions)
    }
  }

  private func downloadImageAndShowNotification(content: UNNotificationContent, imageURL: URL) {
    Task {
      do {
        let downloadedURL = try await HTTPClient.shared.download(imageURL)

        if let attachment = try? UNNotificationAttachment(identifier: "image", url: downloadedURL, options: nil),
          let newContent = content.mutableCopy() as? UNMutableNotificationContent
        {
          newContent.attachments = [attachment]
          var newUserInfo = newContent.userInfo
          newUserInfo["clix_image_handled"] = true
          newContent.userInfo = newUserInfo
          let userInfo = content.userInfo
          let identifier =
            (userInfo["gcm.message_id"] as? String) ?? (userInfo["message_id"] as? String) ?? UUID().uuidString
          let request = UNNotificationRequest(identifier: identifier, content: newContent, trigger: nil)
          try? await UNUserNotificationCenter.current().add(request)
        }
      } catch {
        ClixLogger.error("Failed to download image for notification", error: error)
      }
    }
  }

  open func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    ClixLogger.debug("Push notification tapped")
    notificationTapped(userInfo: response.notification.request.content.userInfo)
    completionHandler()
  }

  open func application(
    _ application: UIApplication,
    didReceiveRemoteNotification payload: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    ClixLogger.debug("Push notification delivered silently")
    notificationDeliveredSilently(payload: payload, completionHandler: completionHandler)
  }

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

  open func notificationDeliveredInForeground(notification: UNNotification) -> UNNotificationPresentationOptions {
    guard #available(iOS 14.0, *) else {
      return [.alert, .sound, .badge]
    }
    return [.list, .banner, .sound, .badge]
  }

  private func parseClixPayload(from userInfo: [AnyHashable: Any]) -> [String: Any]? {
    guard let clix = userInfo["clix"] else { return nil }
    ClixLogger.debug("Clix notification data: \(clix)")

    if let clixData = clix as? [String: Any] {
      return clixData
    }
    if let clixString = clix as? String {
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

  private func openLandingURLIfPresent(from userInfo: [AnyHashable: Any]) -> Bool {
    guard let clixData = parseClixPayload(from: userInfo),
      let landingURL = clixData["landing_url"] as? String,
      let url = URL(string: landingURL)
    else { return false }

    DispatchQueue.main.async {
      self.openURLSafely(url)
    }
    return true
  }

  private func openURLSafely(_ url: URL) {
    guard UIApplication.shared.canOpenURL(url) else {
      ClixLogger.error("Cannot open URL scheme: \(url)")
      return
    }

    if UIApplication.shared.applicationState == .active {
      UIApplication.shared.open(url, options: [:]) { success in
        if success {
          ClixLogger.debug("Successfully opened URL: \(url)")
        } else {
          ClixLogger.error("Failed to open URL: \(url)")
        }
      }
    } else {
      ClixLogger.debug("App not active, storing URL to open when app becomes active: \(url)")
      pendingURL = url
    }
  }

  private func setupAppStateNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
  }

  @objc private func applicationDidBecomeActive() {
    if let url = pendingURL {
      ClixLogger.debug("App became active, opening pending URL: \(url)")
      pendingURL = nil

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        UIApplication.shared.open(url, options: [:]) { success in
          if success {
            ClixLogger.debug("Successfully opened pending URL: \(url)")
          } else {
            ClixLogger.error("Failed to open pending URL: \(url)")
          }
        }
      }
    }
  }

  open func notificationTapped(userInfo: [AnyHashable: Any]) {
    handleNotificationTapped(userInfo: userInfo)
    _ = openLandingURLIfPresent(from: userInfo)
  }

  open func notificationDeliveredSilently(
    payload: [AnyHashable: Any],
    completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    Task {
      do {
        try await handleNotificationReceived(userInfo: payload)
        completionHandler(.newData)
      } catch {
        ClixLogger.error("Failed to handle silent notification: \(error)")
        completionHandler(.failed)
      }
    }
  }

  open func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let token = fcmToken else {
      ClixLogger.warn("FCM registration token is nil.")
      return
    }
    ClixLogger.debug("FCM registration token received: \(token)")
    Task {
      do {
        try await processToken(token, tokenType: "FCM")
        ClixLogger.debug("FCM token successfully processed after SDK initialization")
      } catch {
        ClixLogger.error("Failed to process FCM token: \(error)")
      }
    }
  }

  open func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
    ClixLogger.debug("FCM push notification received (foreground)")
    handleNotificationReceived(userInfo: userInfo)
    _ = openLandingURLIfPresent(from: userInfo)
  }

  private func processToken(_ token: String, tokenType: String) async throws {
    let deviceService = try await Clix.shared.getWithWait(\.deviceService)
    try await deviceService.upsertToken(token, tokenType: tokenType)
  }

  private func handleNotificationReceived(userInfo: [AnyHashable: Any]) {
    Task {
      do {
        try await handleNotificationReceived(userInfo: userInfo)
      } catch {
        ClixLogger.error("Failed to handle notification received: \(error)")
      }
    }
  }

  private func handleNotificationTapped(userInfo: [AnyHashable: Any]) {
    Task {
      do {
        try await handleNotificationTapped(userInfo: userInfo)
      } catch {
        ClixLogger.error("Failed to handle notification tapped: \(error)")
      }
    }
  }

  private func handleNotificationReceived(userInfo: [AnyHashable: Any]) async throws {
    let notificationService = try await Clix.shared.getWithWait(\.notificationService)
    notificationService.handlePushReceived(userInfo: userInfo)
  }

  private func handleNotificationTapped(userInfo: [AnyHashable: Any]) async throws {
    let notificationService = try await Clix.shared.getWithWait(\.notificationService)
    notificationService.handlePushTapped(userInfo: userInfo)
  }
}
