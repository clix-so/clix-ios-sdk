import Foundation

class EventAPIService: BaseAPIService {
  static let shared = EventAPIService()

  func trackEvent(name: String, properties: [String: Any]?, userId: String?) async throws {
    let path = "/v1/events"
    do {
      let url = try makeURL(path: path)
      let headers = try makeHeaders()

      struct RequestBody: Encodable {
        let name: String
        let properties: AnyCodable?
        let userId: String?
      }
      let encodableProperties = properties.map { AnyCodable($0) }
      let body = RequestBody(name: name, properties: encodableProperties, userId: userId)
      let bodyData = try encodeBody(body)

      struct EmptyResponse: Decodable {}
      _ = try await httpClient.post(url: url, headers: headers, body: bodyData, responseType: EmptyResponse.self)
    } catch {
      throw handleRequestError(error)
    }
  }
}
