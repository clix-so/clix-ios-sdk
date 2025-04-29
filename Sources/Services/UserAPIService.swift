import Foundation

class UserAPIService: BaseAPIService {
  static let shared = UserAPIService()

  func registerDevice(token: String, userId: String?) async throws {
    let path = "/v1/devices"
    do {
      let url = try makeURL(path: path)
      let headers = try makeHeaders()

      struct RequestBody: Encodable {
        let token: String
        let platform: String = "ios"
        let userId: String?
      }
      let body = RequestBody(token: token, userId: userId)
      let bodyData = try encodeBody(body)

      struct EmptyResponse: Decodable {}
      _ = try await httpClient.post(url: url, headers: headers, body: bodyData, responseType: EmptyResponse.self)
    } catch {
      throw handleRequestError(error)
    }
  }

  func setAttribute(key: String, value: Any, userId: String?) async throws {
    let path = "/v1/user-attributes"
    do {
      let url = try makeURL(path: path)
      let headers = try makeHeaders()

      struct RequestBody: Encodable {
        let key: String
        let value: AnyCodable
        let userId: String?
      }
      let body = RequestBody(key: key, value: AnyCodable(value), userId: userId)
      let bodyData = try encodeBody(body)

      struct EmptyResponse: Decodable {}
      _ = try await httpClient.post(url: url, headers: headers, body: bodyData, responseType: EmptyResponse.self)
    } catch {
      throw handleRequestError(error)
    }
  }
}
