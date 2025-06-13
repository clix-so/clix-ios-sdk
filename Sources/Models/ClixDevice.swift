import Foundation

struct ClixDevice: Codable {
  var id: String
  var platform: String
  var model: String
  var manufacturer: String
  var osName: String
  var osVersion: String
  var localeRegion: String
  var localeLanguage: String
  var timezone: String
  var appName: String
  var appVersion: String
  var sdkType: String
  var sdkVersion: String
  var adId: String?
  var isPushPermissionGranted: Bool
  var pushToken: String?
  var pushTokenType: String?
}
