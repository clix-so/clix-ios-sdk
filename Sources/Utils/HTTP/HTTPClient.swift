import Foundation

// internal (default) access level
class HTTPClient {
  // shared 인스턴스를 private으로 변경
  private static let shared = HTTPClient()
  private let session: URLSession

  // internal (default) access level
  init(session: URLSession = .shared) {
    self.session = session
  }

  // internal (default) access level
  func request<T: Decodable>(_ req: HTTPRequest, responseType: T.Type) async throws -> HTTPResponse<T> {
    var urlComponents = URLComponents(url: req.url, resolvingAgainstBaseURL: false)
    if let query = req.query {
      urlComponents?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
    guard let finalURL = urlComponents?.url else {
      throw HTTPError.invalidURL
    }
    var request = URLRequest(url: finalURL)
    request.httpMethod = req.method.rawValue
    if let headers = req.headers {
      for (key, value) in headers {
        request.setValue(value, forHTTPHeaderField: key)
      }
    }
    request.httpBody = req.body
    do {
      // iOS 13 호환성을 위해 session.data(for:) 대신 session.dataTask 사용 필요
      // TODO: request 메서드를 async/await 대신 dataTask와 continuation으로 재작성 필요
      let (data, response) = try await session.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw HTTPError.network(
          NSError(domain: "HTTPClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "No HTTPURLResponse"])
        )
      }
      if !(200...299).contains(httpResponse.statusCode) {
        throw HTTPError.server(statusCode: httpResponse.statusCode, data: data)
      }
      let decoded = try JSONDecoder().decode(T.self, from: data)
      return HTTPResponse(data: decoded, statusCode: httpResponse.statusCode, headers: httpResponse.allHeaderFields)
    } catch let error as HTTPError {
      throw error
    } catch let error as DecodingError {
      throw HTTPError.decoding(error)
    } catch {
      throw HTTPError.network(error)
    }
  }

  // Sugar methods (internal)
  func get<T: Decodable>(
    url: URL,
    headers: [String: String]? = nil,
    query: [String: String]? = nil,
    responseType: T.Type
  ) async throws -> HTTPResponse<T> {
    let req = HTTPRequest(url: url, method: .get, headers: headers, query: query)
    return try await request(req, responseType: responseType)
  }

  func post<T: Decodable>(
    url: URL,
    headers: [String: String]? = nil,
    query: [String: String]? = nil,
    body: Data? = nil,
    responseType: T.Type
  ) async throws -> HTTPResponse<T> {
    let req = HTTPRequest(url: url, method: .post, headers: headers, query: query, body: body)
    return try await request(req, responseType: responseType)
  }

  func put<T: Decodable>(
    url: URL,
    headers: [String: String]? = nil,
    query: [String: String]? = nil,
    body: Data? = nil,
    responseType: T.Type
  ) async throws -> HTTPResponse<T> {
    let req = HTTPRequest(url: url, method: .put, headers: headers, query: query, body: body)
    return try await request(req, responseType: responseType)
  }

  func delete<T: Decodable>(
    url: URL,
    headers: [String: String]? = nil,
    query: [String: String]? = nil,
    body: Data? = nil,
    responseType: T.Type
  ) async throws -> HTTPResponse<T> {
    let req = HTTPRequest(url: url, method: .delete, headers: headers, query: query, body: body)
    return try await request(req, responseType: responseType)
  }

  /// Downloads a file from the given URL to a temporary location. (internal)
  func download(url: URL) async throws -> URL {
    try await withCheckedThrowingContinuation { continuation in
      let task = session.downloadTask(with: url) { tempLocalURL, response, error in
        if let error = error {
          continuation.resume(throwing: HTTPError.network(error))
          return
        }

        guard let tempLocalURL = tempLocalURL else {
          continuation.resume(
            throwing: HTTPError.network(
              NSError(
                domain: "HTTPClient",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Missing temporary file URL after download."]
              )
            )
          )
          return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
          continuation.resume(
            throwing: HTTPError.network(
              NSError(domain: "HTTPClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "No HTTPURLResponse"])
            )
          )
          return
        }

        if !(200...299).contains(httpResponse.statusCode) {
          let errorData = try? Data(contentsOf: tempLocalURL)
          continuation.resume(throwing: HTTPError.server(statusCode: httpResponse.statusCode, data: errorData))
          return
        }

        let fileManager = FileManager.default
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let destinationURL = temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(
          url.pathExtension
        )

        do {
          if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
          }
          try fileManager.moveItem(at: tempLocalURL, to: destinationURL)
          continuation.resume(returning: destinationURL)
        } catch {
          continuation.resume(throwing: HTTPError.network(error))
        }
      }
      task.resume()
    }
  }
}

// 아래 중복 정의된 타입들을 모두 삭제합니다.
// struct HTTPRequest { ... }
// struct HTTPResponse<T> { ... }
// enum HTTPMethod: String { ... }
// enum HTTPError: Error { ... }
// AnyCodable 정의 주석도 삭제합니다.
