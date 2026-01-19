import Foundation

class LiveActivityAPIService: ClixAPIClient {
  func registerLiveActivityStartToken(
    deviceId: String,
    activityType: String,
    token: String
  ) async throws {
    let path = "/devices/\(deviceId)/live-activity-start-tokens"
    let body = ["attributes_type": activityType, "push_to_start_token": token]
    let _: EmptyResponse = try await post(path: path, data: body)
  }
}
