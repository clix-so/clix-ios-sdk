import Foundation

class VisitorAPIService: ClixAPIClient {
  func setUserId(_ userId: String) async throws {
    let visitorId = try Clix.getShared().userService.getCurrentUser().visitorId
    let path = "/v1/vistor/\(visitorId)/userId"
    let _: HTTPResponse<AnyCodable> = try await post(path: path, data: AnyCodable(["userId": userId]))
  }

  func setProperties(_ properties: [String: AnyCodable?]) async throws {
    let visitorId = try Clix.getShared().userService.getCurrentUser().visitorId
    let path = "/v1/vistor/\(visitorId)/properties"
    let _: HTTPResponse<AnyCodable> = try await post(path: path, data: AnyCodable(properties))
  }
}
