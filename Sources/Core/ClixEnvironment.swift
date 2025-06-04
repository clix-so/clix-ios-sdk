import Foundation
import UIKit
import AdSupport
import UserNotifications

/// Manages environment and device information for Clix SDK
actor ClixEnvironment {
  let config: ClixConfig
  let deviceId: String
  private var device: ClixDevice

  init(config: ClixConfig, deviceId: String) async {
    self.config = config
    self.deviceId = deviceId
    self.device = await ClixEnvironment.createDevice(config: config, deviceId: deviceId)
  }

  func getDevice() -> ClixDevice {
    device
  }

  func setDevice(_ device: ClixDevice) {
    self.device = device
  }

  /// Returns a string representation of the ClixEnvironment instance.
  public func toString() -> String {
    "ClixEnvironment(config: \(config), deviceId: \(deviceId), device: \(device))"
  }

  @MainActor
  private static func createDevice(config: ClixConfig, deviceId: String) async -> ClixDevice {
    let device = UIDevice.current
    let locale = Locale.current
    let timezone = TimeZone.current
    let appName = Bundle.main.bundleIdentifier ?? ""
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    // Get advertising identifier (IDFA)
    let adId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
    
    // Check push notification permission status
    var isPushPermissionGranted = false
    let notificationCenter = UNUserNotificationCenter.current()
    let settings = await notificationCenter.notificationSettings()
    if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
      isPushPermissionGranted = true
    }
    
    return ClixDevice(
      id: deviceId,
      platform: "iOS",
      model: device.model,
      manufacturer: "Apple",
      osName: device.systemName,
      osVersion: device.systemVersion,
      localeRegion: locale.regionCode ?? "",
      localeLanguage: locale.languageCode ?? "",
      timezone: timezone.identifier,
      appName: appName,
      appVersion: appVersion,
      sdkType: "Native",
      sdkVersion: Clix.version,
      adId: adId,  // 광고 ID 설정
      isPushPermissionGranted: isPushPermissionGranted,  // 푸시 권한 상태 설정
      pushToken: "",
      pushTokenType: "FCM"
    )
  }
}
