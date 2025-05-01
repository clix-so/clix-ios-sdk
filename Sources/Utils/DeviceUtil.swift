import Foundation
import UIKit

class DeviceUtil {
  /// Get current device information
  /// - Returns: Dictionary containing device information
  static func getDeviceInfo() -> [String: Any] {
    let device = UIDevice.current
    return [
      "name": device.name,
      "model": device.model,
      "systemName": device.systemName,
      "systemVersion": device.systemVersion,
      "identifierForVendor": getDeviceId(),
      "isSimulator": isSimulator(),
    ]
  }

  /// Get device ID
  /// - Returns: Device ID
  static func getDeviceId() -> String {
    UIDevice.current.identifierForVendor?.uuidString ?? ""
  }

  /// Check if the current device is a simulator
  /// - Returns: Boolean indicating if the device is a simulator
  static func isSimulator() -> Bool {
    #if targetEnvironment(simulator)
      return true
    #else
      return false
    #endif
  }

  /// Get device orientation
  /// - Returns: Current device orientation
  static func getDeviceOrientation() -> UIDeviceOrientation {
    UIDevice.current.orientation
  }

  /// Get device battery level
  /// - Returns: Battery level as a percentage (0.0 to 1.0)
  static func getBatteryLevel() -> Float {
    UIDevice.current.isBatteryMonitoringEnabled = true
    return UIDevice.current.batteryLevel
  }

  /// Get device battery state
  /// - Returns: Current battery state
  static func getBatteryState() -> UIDevice.BatteryState {
    UIDevice.current.isBatteryMonitoringEnabled = true
    return UIDevice.current.batteryState
  }
}
