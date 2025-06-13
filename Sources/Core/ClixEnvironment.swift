import Foundation

struct ClixEnvironment {
  let config: ClixConfig
  var device: ClixDevice

  func getDevice() -> ClixDevice {
    device
  }

  mutating func setDevice(_ newDevice: ClixDevice) {
    self.device = newDevice
  }

  func toString() -> String {
    "Environment(deviceId: \(device.id), config: \(config.projectId))"
  }
}
