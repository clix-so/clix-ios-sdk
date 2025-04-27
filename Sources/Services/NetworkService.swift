import Foundation

public class NetworkService {
  public static let shared = NetworkService()

  private let httpClient: HTTPClient
  private var apiKey: String?
  private var endpoint: String?

  init(httpClient: HTTPClient = HTTPClient()) {
    self.httpClient = httpClient
  }

  public func configure(apiKey: String, endpoint: String) {
    self.apiKey = apiKey
    self.endpoint = endpoint.hasSuffix("/") ? String(endpoint.dropLast()) : endpoint
  }

  private func makeHeaders() throws -> [String: String] {
    guard let apiKey = apiKey else {
      throw ClixError.notInitialized
    }
    return [
      "Content-Type": "application/json",
      "X-API-Key": apiKey,
    ]
  }

  private func makeURL(path: String) throws -> URL {
    guard let endpoint = endpoint,
      let url = URL(string: endpoint + path)
    else {
      throw ClixError.invalidURL
    }
    return url
  }

  private func handleRequestError(_ error: Error) -> ClixError {
    guard let httpError = error as? HTTPError else {
      if let clixError = error as? ClixError {
        return clixError
      }
      return .networkError(error)
    }
    switch httpError {
    case .invalidURL:
      return .invalidURL
    case .network(let underlyingError):
      return .networkError(underlyingError)
    case .server(let statusCode, let data):
      print(
        "[NetworkService] Server error: \(statusCode), Data: \(String(data: data ?? Data(), encoding: .utf8) ?? "N/A")"
      )
      return .networkError(httpError)
    case .decoding(let decError):
      return .decodingError(decError)
    }
  }

  private func encodeBody<T: Encodable>(_ body: T) throws -> Data {
    do {
      let encoder = JSONEncoder()
      return try encoder.encode(body)
    } catch {
      throw ClixError.encodingError
    }
  }

  public func registerDevice(token: String, userId: String?) async throws {
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

  public func trackEvent(name: String, properties: [String: Any]?, userId: String?) async throws {
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

  public func setAttribute(key: String, value: Any, userId: String?) async throws {
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

  public func downloadMedia(url: URL) async throws -> URL {
    do {
      return try await httpClient.download(url: url)
    } catch {
      throw handleRequestError(error)
    }
  }
}
