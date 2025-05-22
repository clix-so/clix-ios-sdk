import Foundation

struct EmptyResponse: Decodable {}

class DeviceAPIService: ClixAPIClient {
  func upsertDevice(device: ClixDevice) async throws {
    let path = "/devices/\(device.id)"
    let _: EmptyResponse = try await post(path: path, data: device)
  }

  func setProjectUserId(deviceId: String, projectUserId: String) async throws {
    let path = "/devices/\(deviceId)/user/project-user-id"
    let body = ["projectUserId": projectUserId]
    let _: EmptyResponse = try await post(path: path, data: body)
  }

  func upsertUserProperties(deviceId: String, properties: [ClixUserProperty]) async throws {
    let path = "/devices/\(deviceId)/user/properties"
    let _: EmptyResponse = try await post(path: path, data: properties)
  }

  func removeUserProperties(deviceId: String, propertyNames: [String]) async throws {
    let path = "/devices/\(deviceId)/user/properties"
    let params = ["names": propertyNames]
    let _: EmptyResponse = try await delete(path: path, params: params)
  }
}
