import Foundation

class LiveActivityAPIService: ClixAPIClient {
  func setPushToStartToken(
    deviceId: String,
    activityType: String,
    token: String
  ) async throws {
    let path = "/devices/\(deviceId)/live-activities/\(activityType)/push-to-start-token"
    let body = ["token": token]
    let _: EmptyResponse = try await post(path: path, data: body)
  }
}
