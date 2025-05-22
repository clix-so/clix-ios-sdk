import Foundation
import UIKit

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

  @MainActor
  private static func createDevice(config: ClixConfig, deviceId: String) -> ClixDevice {
    let device = UIDevice.current
    let locale = Locale.current
    let timezone = TimeZone.current
    let appName = Bundle.main.bundleIdentifier ?? ""
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
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
      adId: nil,  // iOS에서 광고 ID는 별도 처리 필요
      isPushPermissionGranted: false,  // 추후 업데이트 필요
      pushToken: "",
      pushTokenType: "APNS"
    )
  }
}
