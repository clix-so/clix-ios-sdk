import Foundation

class HTTPClient {
  static let shared = HTTPClient()
  private let session: URLSession

  init(session: URLSession = .shared) {
    self.session = session
  }

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

  // Sugar methods
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
}
