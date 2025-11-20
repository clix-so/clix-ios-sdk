import FirebaseCore
import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

@available(iOSApplicationExtension, unavailable)
public class ClixNotification: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
  public static let shared = ClixNotification()

  // MARK: - State
  private var pendingURL: URL?
  private var autoOpenLandingOnTap: Bool = true
  private var processedTappedEvents: Set<String> = []

  // MARK: - Handlers
  public typealias NotificationWillShowHandler = (UNNotification) -> UNNotificationPresentationOptions
  public typealias NotificationOpenedHandler = ([AnyHashable: Any]) -> Void
  public typealias ApnsTokenErrorHandler = (Error) -> Void
  private var willShowHandler: NotificationWillShowHandler?
  private var openedHandler: NotificationOpenedHandler?
  private var apnsTokenErrorHandler: ApnsTokenErrorHandler?

  // MARK: - Lifecycle
  private override init() { super.init() }
  deinit { NotificationCenter.default.removeObserver(self) }

  // MARK: - Configuration
  /// Configure push notification handling with optional settings.
  public func configure(
    autoRequestPermission: Bool = false,
    autoHandleLandingURL: Bool = true
  ) {
    Messaging.messaging().delegate = self
    if UNUserNotificationCenter.current().delegate == nil {
      UNUserNotificationCenter.current().delegate = self
    }

    self.autoOpenLandingOnTap = autoHandleLandingURL

    DispatchQueue.main.async {
      UIApplication.shared.registerForRemoteNotifications()
    }

    if autoRequestPermission { requestPermission() }
    setupAppStateNotifications()
  }

  @available(*, deprecated, renamed: "configure(autoRequestPermission:)")
  public func setup(autoRequestAuthorization: Bool = true) {
    configure(autoRequestPermission: autoRequestAuthorization)
  }

  public func handleLaunchOptions(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
    if let launchOptions = launchOptions, let payload = launchOptions[.remoteNotification] as? [AnyHashable: Any] {
      ClixLogger.debug("App launched from push notification")

      let messageId = extractMessageId(from: payload)
      if let messageId = messageId {
        processedTappedEvents.insert(messageId)
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.handleNotificationTapped(userInfo: payload)
      }
    }
  }

  /// Register handler for messages received while app is in foreground.
  public func onMessage(_ handler: @escaping NotificationWillShowHandler) {
    willShowHandler = handler
  }

  /// Register handler for when user taps on a notification.
  public func onNotificationOpened(_ handler: @escaping NotificationOpenedHandler) {
    openedHandler = handler
  }

  /// Register handler for APNs token registration errors.
  public func onApnsTokenError(_ handler: @escaping ApnsTokenErrorHandler) {
    apnsTokenErrorHandler = handler
  }

  @available(*, deprecated, renamed: "onMessage")
  public func setNotificationWillShowInForegroundHandler(_ handler: @escaping NotificationWillShowHandler) {
    onMessage(handler)
  }

  @available(*, deprecated, renamed: "onNotificationOpened")
  public func setNotificationOpenedHandler(_ handler: @escaping NotificationOpenedHandler) {
    onNotificationOpened(handler)
  }

  @available(*, deprecated, message: "Use configure(autoHandleLandingURL:) instead")
  public func setAutoOpenLandingOnTap(_ enabled: Bool) { autoOpenLandingOnTap = enabled }

  /// Set the APNs device token for push notifications.
  public func setApnsToken(_ deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    ClixLogger.debug("APNS token set for Firebase Messaging.")
  }

  @available(*, deprecated, renamed: "setApnsToken")
  public func handleAPNSToken(_ deviceToken: Data) {
    setApnsToken(deviceToken)
  }

  @available(*, deprecated, message: "Use onApnsTokenError(_:) to register error handler instead")
  public func handleAPNSRegistrationError(_ error: Error) {
    ClixLogger.error("Failed to register for remote notifications", error: error)
    apnsTokenErrorHandler?(error)
  }

  // MARK: - UNUserNotificationCenterDelegate
  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    handleWillPresent(notification: notification, completionHandler: completionHandler)
  }

  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    handleDidReceive(response: response, completionHandler: completionHandler)
  }

  // MARK: - Public Delegate Forwarding Helpers
  public func handleWillPresent(
    notification: UNNotification,
    completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    ClixLogger.debug("Push notification delivered in foreground")
    let userInfo = notification.request.content.userInfo
    handleNotificationReceived(userInfo: userInfo)

    // 1) App-level handler has priority
    if let handler = willShowHandler {
      completionHandler(handler(notification))
      return
    }

    // 2) If already handled for image, show default options
    if userInfo["clix_image_handled"] as? Bool == true {
      completionHandler(notificationDeliveredInForeground(notification: notification))
      return
    }

    // 3) Try to fetch image and re-post
    if let imageURL = extractImageURL(from: userInfo) {
      downloadImageAndShowNotification(content: notification.request.content, imageURL: imageURL)
      completionHandler([])
      return
    }

    // 4) Default presentation if nothing special
    completionHandler(notificationDeliveredInForeground(notification: notification))
  }

  public func handleDidReceive(
    response: UNNotificationResponse,
    completionHandler: @escaping () -> Void
  ) {
    ClixLogger.debug("Push notification tapped")
    let userInfo = response.notification.request.content.userInfo

    let messageId = extractMessageId(from: userInfo)
    if let messageId = messageId {
      if processedTappedEvents.contains(messageId) {
        completionHandler()
        return
      }
      processedTappedEvents.insert(messageId)
    }

    if let handler = openedHandler { handler(userInfo) }
    notificationTapped(userInfo: userInfo)
    completionHandler()
  }

  // MARK: - MessagingDelegate
  public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
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

  // MARK: - High-level Handlers
  public func handleBackgroundNotification(
    _ payload: [AnyHashable: Any],
    completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    ClixLogger.debug("Push notification received (background)")
    handleNotificationReceived(userInfo: payload)
    completionHandler(.newData)
  }

  public func handleForegroundNotification(_ userInfo: [AnyHashable: Any]) {
    ClixLogger.debug("Push notification received (foreground)")
    handleNotificationReceived(userInfo: userInfo)
    // Respect UX: do not auto-open URLs on foreground receipt
  }

  internal func handleNotificationReceived(userInfo: [AnyHashable: Any]) {
    executeNotificationTask("notification received") {
      let notificationService = try await Clix.shared.getWithWait(\.notificationService)
      notificationService.handlePushReceived(userInfo: userInfo)
    }
  }

  internal func handleNotificationTapped(userInfo: [AnyHashable: Any]) {
    executeNotificationTask("notification tapped") {
      let notificationService = try await Clix.shared.getWithWait(\.notificationService)
      notificationService.handlePushTapped(userInfo: userInfo)
    }
  }

  // MARK: - Deep Link Helpers
  internal func openLandingURLIfPresent(from userInfo: [AnyHashable: Any]) -> Bool {
    guard let payload = ClixPushNotificationPayload.decode(from: userInfo),
      let landingURL = payload.landingUrl,
      let url = URL(string: landingURL)
    else { return false }
    DispatchQueue.main.async { self.openURLSafely(url) }
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

  private func notificationTapped(userInfo: [AnyHashable: Any]) {
    handleNotificationTapped(userInfo: userInfo)
    if autoOpenLandingOnTap { _ = openLandingURLIfPresent(from: userInfo) }
  }

  // MARK: - Utilities
  private func executeNotificationTask(_ context: String, _ operation: @escaping () async throws -> Void) {
    Task {
      do {
        try await operation()
      } catch {
        ClixLogger.error("Failed to handle \(context): \(error)")
      }
    }
  }

  private func extractImageURL(from userInfo: [AnyHashable: Any]) -> URL? {
    let sources: [(String, Any?)] = [
      ("clix data", ClixPushNotificationPayload.decode(from: userInfo)?.imageUrl),
      ("userInfo", userInfo["image_url"]),
      ("fcm_options", (userInfo["fcm_options"] as? [String: Any])?["image_url"]),
      ("fcm_options dictionary", (userInfo["fcm_options"] as? NSDictionary)?["image_url"]),
    ]

    for (source, value) in sources {
      if let imageURLString = value as? String, let url = URL(string: imageURLString) {
        ClixLogger.debug("Found image_url in \(source): \(imageURLString)")
        return url
      }
    }
    return nil
  }

  private func downloadImageAndShowNotification(content: UNNotificationContent, imageURL: URL) {
    Task {
      do {
        let (localURL, _) = try await URLSession.shared.download(from: imageURL)

        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let fileName = imageURL.lastPathComponent.isEmpty ? "image.png" : imageURL.lastPathComponent
        let destinationURL = tempDirectory.appendingPathComponent(fileName)

        try fileManager.moveItem(at: localURL, to: destinationURL)

        if let attachment = try? UNNotificationAttachment(identifier: "image", url: destinationURL, options: nil),
          let newContent = content.mutableCopy() as? UNMutableNotificationContent
        {
          newContent.attachments = [attachment]
          var newUserInfo = newContent.userInfo
          newUserInfo["clix_image_handled"] = true
          newContent.userInfo = newUserInfo
          let userInfo = content.userInfo
          let identifier =
            (userInfo["gcm.message_id"] as? String) ?? (userInfo["message_id"] as? String) ?? UUID().uuidString

          UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
          let request = UNNotificationRequest(identifier: identifier, content: newContent, trigger: nil)
          try await UNUserNotificationCenter.current().add(request)
        } else {
          ClixLogger.error("Failed to create attachment or mutable content")
        }
      } catch {
        ClixLogger.error("Failed to download image for notification", error: error)
      }
    }
  }

  /// Request notification permissions from the user.
  public func requestPermission() {
    Task {
      do {
        let notificationService = try await Clix.shared.getWithWait(\.notificationService)
        try await notificationService.requestNotificationPermission()
        ClixLogger.debug("Notification permission requested successfully")
      } catch {
        ClixLogger.error("Failed to request notification permission", error: error)
      }
    }
  }

  @available(*, deprecated, renamed: "requestPermission")
  public func requestNotificationPermission() {
    requestPermission()
  }

  private func notificationDeliveredInForeground(notification: UNNotification) -> UNNotificationPresentationOptions {
    guard #available(iOS 14.0, *) else { return [.alert, .sound, .badge] }
    return [.list, .banner, .sound, .badge]
  }

  private func extractMessageId(from userInfo: [AnyHashable: Any]) -> String? {
    ClixPushNotificationPayload.decode(from: userInfo)?.messageId
  }

  private func processToken(_ token: String, tokenType: String) async throws {
    let deviceService = try await Clix.shared.getWithWait(\.deviceService)
    try await deviceService.upsertToken(token, tokenType: tokenType)
  }
}
