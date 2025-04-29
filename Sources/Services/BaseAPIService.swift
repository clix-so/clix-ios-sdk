import Foundation

class BaseAPIService {
  let httpClient: HTTPClient
  var apiKey: String?
  var endpoint: String?

  init(httpClient: HTTPClient = HTTPClient()) {
    self.httpClient = httpClient
  }

  func configure(apiKey: String, endpoint: String) {
    self.apiKey = apiKey
    self.endpoint = endpoint.hasSuffix("/") ? String(endpoint.dropLast()) : endpoint
  }

  func makeHeaders() throws -> [String: String] {
    guard let apiKey = apiKey else {
      throw ClixError.notInitialized
    }
    return [
      "Content-Type": "application/json",
      "X-API-Key": apiKey,
    ]
  }

  func makeURL(path: String) throws -> URL {
    guard let endpoint = endpoint,
      let url = URL(string: endpoint + path)
    else {
      throw ClixError.invalidURL
    }
    return url
  }

  func handleRequestError(_ error: Error) -> ClixError {
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
    case let .server(statusCode, data):
      let errorMessage = data.map { String(decoding: $0, as: UTF8.self) } ?? "N/A"
      ClixLogger.shared.log(
        level: .error,
        category: .network,
        message: "Server error: \(statusCode), Data: \(errorMessage)"
      )
      return .networkError(httpError)
    case .decoding(let decError):
      return .decodingError(decError)
    }
  }

  func encodeBody<T: Encodable>(_ body: T) throws -> Data {
    do {
      let encoder = JSONEncoder()
      return try encoder.encode(body)
    } catch {
      throw ClixError.encodingError
    }
  }
}
