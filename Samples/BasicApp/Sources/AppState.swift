import Foundation
import Combine

class AppState: ObservableObject {
  static let shared = AppState()

  @Published var deviceId: String = "Loading..."
  @Published var fcmToken: String = "Loading..."

  private init() {}

  func updateDeviceId(_ deviceId: String?) {
    self.deviceId = deviceId ?? "Not available"
  }

  func updateFCMToken(_ token: String?) {
    self.fcmToken = token ?? "Not available"
  }
}
