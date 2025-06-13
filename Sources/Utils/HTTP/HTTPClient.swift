import Foundation

class HTTPClient {
  static let shared = HTTPClient()

  private let session: URLSession
  private let jsonDecoder: JSONDecoder
  private let jsonEncoder: JSONEncoder

  init(session: URLSession = .shared) {
    self.session = session

    let decoder = JSONDecoder()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    decoder.dateDecodingStrategy = .formatted(formatter)
    self.jsonDecoder = decoder

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    self.jsonEncoder = encoder
  }

  private func buildRequestHeaders(_ headers: [String: String]?) -> [String: String] {
    var result = ["Content-Type": "application/json"]
    headers?.forEach { result[$0.key] = $0.value }
    return result
  }

  private func buildRequestURL(url: URL, params: [String: Any]?) throws -> URL {
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
      throw ClixError.invalidURL
    }
    if let params = params {
      components.queryItems = params.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
    }
    guard let url = components.url else {
      throw ClixError.invalidURL
    }
    return url
  }

  func request<Res: Decodable>(_ request: HTTPRequest) async throws -> HTTPResponse<Res> {
    let finalURL = try buildRequestURL(url: request.url, params: request.params)
    var urlRequest = URLRequest(url: finalURL)
    urlRequest.httpMethod = request.method.rawValue
    urlRequest.allHTTPHeaderFields = buildRequestHeaders(request.headers)

    if let data = request.data {
      urlRequest.httpBody = try jsonEncoder.encode(data)
    }

    let (data, response) = try await session.data(for: urlRequest)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw ClixError.networkError(NSError(domain: "HTTPClient", code: -1, userInfo: nil))
    }
    let dataString = String(data: data, encoding: .utf8) ?? "Could not convert data to string"
    ClixLogger.debug(
      "HTTPClient Request Response: URL: \(finalURL), Status: \(httpResponse.statusCode), Data: \(data) \(dataString)"
    )
    guard (200...299).contains(httpResponse.statusCode) else {
      throw ClixError.invalidResponse
    }
    let decoded = try jsonDecoder.decode(Res.self, from: data)
    return HTTPResponse(data: decoded, statusCode: httpResponse.statusCode, headers: httpResponse.allHeaderFields)
  }

  func get<Res: Decodable>(
    _ url: URL,
    params: [String: Any]? = nil,
    headers: [String: String]? = nil
  ) async throws -> HTTPResponse<Res> {
    let request = HTTPRequest(url: url, method: .get, params: params, headers: headers)
    return try await self.request(request)
  }

  func post<Req: Encodable, Res: Decodable>(
    _ url: URL,
    data: Req,
    params: [String: Any]? = nil,
    headers: [String: String]? = nil
  ) async throws -> HTTPResponse<Res> {
    let request = HTTPRequest(url: url, method: .post, params: params, headers: headers, data: data)
    return try await self.request(request)
  }

  func put<Req: Encodable, Res: Decodable>(
    _ url: URL,
    data: Req,
    params: [String: Any]? = nil,
    headers: [String: String]? = nil
  ) async throws -> HTTPResponse<Res> {
    let request = HTTPRequest(url: url, method: .put, params: params, headers: headers, data: data)
    return try await self.request(request)
  }

  func delete<Res: Decodable>(
    _ url: URL,
    params: [String: Any]? = nil,
    headers: [String: String]? = nil
  ) async throws -> HTTPResponse<Res> {
    let request = HTTPRequest(url: url, method: .delete, params: params, headers: headers)
    return try await self.request(request)
  }

  func download(
    _ url: URL,
    params: [String: Any]? = nil,
    headers: [String: String]? = nil
  ) async throws -> URL {
    let finalURL = try buildRequestURL(url: url, params: params)
    var request = URLRequest(url: finalURL)
    request.httpMethod = HTTPMethod.get.rawValue
    request.allHTTPHeaderFields = buildRequestHeaders(headers)
    return try await withCheckedThrowingContinuation { continuation in
      let task = session.downloadTask(with: request) { tempURL, response, error in
        if let error = error {
          continuation.resume(throwing: ClixError.networkError(error))
          return
        }
        guard let tempURL = tempURL, let httpResponse = response as? HTTPURLResponse else {
          continuation.resume(throwing: ClixError.networkError(NSError(domain: "HTTPClient", code: -1, userInfo: nil)))
          return
        }
        guard (200...299).contains(httpResponse.statusCode) else {
          continuation.resume(throwing: ClixError.invalidResponse)
          return
        }
        let destination = URL(fileURLWithPath: NSTemporaryDirectory())
          .appendingPathComponent(UUID().uuidString)
          .appendingPathExtension(url.pathExtension)
        do {
          if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
          }
          try FileManager.default.moveItem(at: tempURL, to: destination)
          continuation.resume(returning: destination)
        } catch {
          continuation.resume(throwing: ClixError.networkError(error))
        }
      }
      task.resume()
    }
  }
}
