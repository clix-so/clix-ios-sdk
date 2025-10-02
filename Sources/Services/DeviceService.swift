import Foundation
import UIKit
import AdSupport
import UserNotifications

actor DeviceService {
  private static let deviceIdKey = "clix_device_id"
  private static let pushTokenTypeFCM = "FCM"
  private static let pushTokenTypeAPNS = "APNS"

  private let deviceApiService: DeviceAPIService
  private let tokenService: TokenService
  private let storageService: StorageService

  init(
    storageService: StorageService,
    tokenService: TokenService,
    deviceApiService: DeviceAPIService = DeviceAPIService()
  ) {
    self.storageService = storageService
    self.tokenService = tokenService
    self.deviceApiService = deviceApiService
  }

  func getCurrentDeviceId() async -> String {
    if let id: String = await storageService.get(Self.deviceIdKey) {
      return id
    }
    let newId = UUID().uuidString
    await storageService.set(Self.deviceIdKey, newId)
    return newId
  }

  func setProjectUserId(_ projectUserId: String) async throws {
    let environment = try Clix.shared.get(\.environment)
    let deviceId = environment.getDevice().id
    try await deviceApiService.setProjectUserId(deviceId: deviceId, projectUserId: projectUserId)
  }

  func removeProjectUserId() async throws {
    try await removeUserProperties(["userId"])
  }

  func updateUserProperties(_ properties: [String: Any]) async throws {
    let environment = try Clix.shared.get(\.environment)
    let deviceId = environment.getDevice().id
    let propertiesList = properties.map { name, value in ClixUserProperty.of(name: name, value: value) }
    ClixLogger.debug("propertiesList:\(propertiesList), properties:\(properties)")
    try await deviceApiService.upsertUserProperties(deviceId: deviceId, properties: propertiesList)
  }

  func removeUserProperties(_ names: [String]) async throws {
    let environment = try Clix.shared.get(\.environment)
    let deviceId = environment.getDevice().id
    try await deviceApiService.removeUserProperties(deviceId: deviceId, propertyNames: names)
  }

  func upsertDevice(_ device: ClixDevice) async throws {
    ClixLogger.debug("upsertDevice: \(device)")
    
    try await deviceApiService.upsertDevice(device: device)
  }

  func upsertToken(_ token: String, tokenType: String = pushTokenTypeFCM) async throws {
    ClixLogger.debug("upsertToken: \(token), \(tokenType)")

    let environment = try Clix.shared.get(\.environment)
    let device = environment.getDevice()

    if (device.pushToken == token && device.pushTokenType == tokenType) {
      ClixLogger.debug("Token already exists, skipping upsert")
      return
    }

    let updatedDevice = ClixDevice(
      id: device.id,
      platform: device.platform,
      model: device.model,
      manufacturer: device.manufacturer,
      osName: device.osName,
      osVersion: device.osVersion,
      localeRegion: device.localeRegion,
      localeLanguage: device.localeLanguage,
      timezone: device.timezone,
      appName: device.appName,
      appVersion: device.appVersion,
      sdkType: device.sdkType,
      sdkVersion: ClixVersion.current,
      adId: device.adId,
      isPushPermissionGranted: device.isPushPermissionGranted,
      pushToken: token,
      pushTokenType: tokenType
    )

    var newEnvironment = environment
    newEnvironment.setDevice(updatedDevice)
    Clix.shared.setEnvironment(newEnvironment)

    await tokenService.saveToken(token)
    try await deviceApiService.upsertDevice(device: updatedDevice)
  }

  func upsertIsPushPermissionGranted(_ isPushPermissionGranted: Bool) async throws {
    ClixLogger.debug("upsertIsPushPermissionGranted: \(isPushPermissionGranted)")

    let environment = try Clix.shared.get(\.environment)
    let device = environment.getDevice()

    if (device.isPushPermissionGranted == isPushPermissionGranted) {
      ClixLogger.debug("Push permission already exists, skipping upsert")
      return
    }

    let updatedDevice = ClixDevice(
      id: device.id,
      platform: device.platform,
      model: device.model,
      manufacturer: device.manufacturer,
      osName: device.osName,
      osVersion: device.osVersion,
      localeRegion: device.localeRegion,
      localeLanguage: device.localeLanguage,
      timezone: device.timezone,
      appName: device.appName,
      appVersion: device.appVersion,
      sdkType: device.sdkType,
      sdkVersion: ClixVersion.current,
      adId: device.adId,
      isPushPermissionGranted: isPushPermissionGranted,
      pushToken: device.pushToken,
      pushTokenType: device.pushTokenType
    )

    var newEnvironment = environment
    newEnvironment.setDevice(updatedDevice)
    Clix.shared.setEnvironment(newEnvironment)

    try await deviceApiService.upsertDevice(device: updatedDevice)
  }

  static func createDevice(deviceId: String, token: String?) async -> ClixDevice {
    let device = await UIDevice.current
    let bundle = Bundle.main
    let notificationCenter = UNUserNotificationCenter.current()
    let settings = await notificationCenter.notificationSettings()

    var isPushPermissionGranted = false
    if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
      isPushPermissionGranted = true
    }

    return ClixDevice(
      id: deviceId,
      platform: "DEVICE_PLATFORM_TYPE_IOS",
      model: await device.model,
      manufacturer: "Apple",
      osName: await device.systemName,
      osVersion: await device.systemVersion,
      localeRegion: Locale.current.regionCode ?? "US",
      localeLanguage: Locale.current.languageCode ?? "en",
      timezone: TimeZone.current.identifier,
      appName: bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Unknown",
      appVersion: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown",
      sdkType: "native",
      sdkVersion: ClixVersion.current,
      adId: ASIdentifierManager.shared().advertisingIdentifier.uuidString,
      isPushPermissionGranted: isPushPermissionGranted,
      pushToken: token,
      pushTokenType: pushTokenTypeFCM
    )
  }
}
