import Foundation

/// A model representing a Clix device and its properties
public struct ClixDevice: Codable {
  public let id: String
  public let platform: String
  public let model: String
  public let manufacturer: String
  public let osName: String
  public let osVersion: String
  public let localeRegion: String
  public let localeLanguage: String
  public let timezone: String
  public let appName: String
  public let appVersion: String?
  public let sdkType: String
  public let sdkVersion: String
  public let adId: String?
  public let isPushPermissionGranted: Bool
  public let pushToken: String
  public let pushTokenType: String

  public init(
    id: String,
    platform: String,
    model: String,
    manufacturer: String,
    osName: String,
    osVersion: String,
    localeRegion: String,
    localeLanguage: String,
    timezone: String,
    appName: String,
    appVersion: String?,
    sdkType: String,
    sdkVersion: String,
    adId: String?,
    isPushPermissionGranted: Bool,
    pushToken: String,
    pushTokenType: String
  ) {
    self.id = id
    self.platform = platform
    self.model = model
    self.manufacturer = manufacturer
    self.osName = osName
    self.osVersion = osVersion
    self.localeRegion = localeRegion
    self.localeLanguage = localeLanguage
    self.timezone = timezone
    self.appName = appName
    self.appVersion = appVersion
    self.sdkType = sdkType
    self.sdkVersion = sdkVersion
    self.adId = adId
    self.isPushPermissionGranted = isPushPermissionGranted
    self.pushToken = pushToken
    self.pushTokenType = pushTokenType
  }
}
