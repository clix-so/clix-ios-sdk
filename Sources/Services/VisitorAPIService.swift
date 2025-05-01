import Foundation

class VisitorAPIService: ClixAPIClient {
  func setUserId(_ userId: String) async throws {
    let visitorId = await Clix.shared.userService.getCurrentUser().visitorId
    let path = "/v1/vistor/\(visitorId)/userIds"
    let _: AnyCodable = try await put(path: path, data: ["userId": userId])
  }

  func removeUserId(_ userId: String) async throws {
    let visitorId = await Clix.shared.userService.getCurrentUser().visitorId
    let path = "/v1/vistor/\(visitorId)/userIds/\(userId)"
    let _: AnyCodable = try await delete(path: path)
  }

  func setProperties(_ properties: [String: Any?]) async throws {
    let visitorId = await Clix.shared.userService.getCurrentUser().visitorId
    let path = "/v1/vistor/\(visitorId)/properties"
    let _: AnyCodable = try await post(path: path, data: properties)
  }

  func registerDevice(token: String) async throws {
    let visitorId = await Clix.shared.userService.getCurrentUser().visitorId
    let path = "/v1/vistor/\(visitorId)/devices"
    let _: AnyCodable = try await post(path: path, data: ["token": token])
  }
}
