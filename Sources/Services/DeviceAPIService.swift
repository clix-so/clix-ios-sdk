import Foundation

struct EmptyResponse: Decodable {}

class DeviceAPIService: ClixAPIClient {
  func upsertDevice(device: ClixDevice) async throws {
    let path = "/devices"
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    let deviceData = try encoder.encode(device)
    let deviceDict = try JSONSerialization.jsonObject(with: deviceData, options: []) as? [String: Any] ?? [:]
    let body = ["devices": [deviceDict]]
    let _: EmptyResponse = try await post(path: path, data: body)
  }

  func setProjectUserId(deviceId: String, projectUserId: String) async throws {
    let path = "/devices/\(deviceId)/user/project-user-id"
    let body = ["project_user_id": projectUserId]
    let _: EmptyResponse = try await post(path: path, data: body)
  }

  func upsertUserProperties(deviceId: String, properties: [ClixUserProperty]) async throws {
    let path = "/devices/\(deviceId)/user/properties"
    let body: [String: Any] = [
      "properties": properties
    ]
    let _: EmptyResponse = try await post(path: path, data: body)
  }

  func removeUserProperties(deviceId: String, propertyNames: [String]) async throws {
    let path = "/devices/\(deviceId)/user/properties"
    let params = ["names": propertyNames]
    let _: EmptyResponse = try await delete(path: path, params: params)
  }
}
