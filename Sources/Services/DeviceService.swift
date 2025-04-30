import Foundation
import UIKit

class DeviceService {
  private let apiService: DeviceAPIService

  init(apiService: DeviceAPIService = DeviceAPIService()) {
    self.apiService = apiService
  }

  /// Register device with the server
  /// - Parameters:
  ///   - token: Device token
  ///   - userId: User ID
  func registerDevice(token: String, userId: String?) async throws {
    try await apiService.registerDevice(token: token, userId: userId)
  }

  /// Get current device information
  /// - Returns: Dictionary containing device information
  func getDeviceInfo() -> [String: Any] {
    let device = UIDevice.current
    return [
      "name": device.name,
      "model": device.model,
      "systemName": device.systemName,
      "systemVersion": device.systemVersion,
      "identifierForVendor": device.identifierForVendor?.uuidString ?? "",
      "isSimulator": isSimulator(),
    ]
  }

  /// Check if the current device is a simulator
  /// - Returns: Boolean indicating if the device is a simulator
  private func isSimulator() -> Bool {
    #if targetEnvironment(simulator)
      return true
    #else
      return false
    #endif
  }

  /// Get device orientation
  /// - Returns: Current device orientation
  func getDeviceOrientation() -> UIDeviceOrientation {
    UIDevice.current.orientation
  }

  /// Get device battery level
  /// - Returns: Battery level as a percentage (0.0 to 1.0)
  func getBatteryLevel() -> Float {
    UIDevice.current.isBatteryMonitoringEnabled = true
    return UIDevice.current.batteryLevel
  }

  /// Get device battery state
  /// - Returns: Current battery state
  func getBatteryState() -> UIDevice.BatteryState {
    UIDevice.current.isBatteryMonitoringEnabled = true
    return UIDevice.current.batteryState
  }
}
