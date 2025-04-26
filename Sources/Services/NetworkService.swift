import Foundation

class NetworkService {
  static let shared = NetworkService()

  private let session: URLSession
  private var apiKey: String?
  private var endpoint: String?

  init() {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 300
    self.session = URLSession(configuration: config)
  }

  func configure(apiKey: String, endpoint: String) {
    self.apiKey = apiKey
    self.endpoint = endpoint
  }

  func registerDevice(token: String, userId: String?) async throws {
    guard let endpoint = endpoint, let apiKey = apiKey else {
      throw ClixError.notInitialized
    }

    guard let urlComponents = URLComponents(string: "\(endpoint)/v1/devices"),
      let url = urlComponents.url
    else {
      throw ClixError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")

    let body: [String: Any] = [
      "token": token,
      "platform": "ios",
      "userId": userId as Any,
    ]

    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    let (_, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw ClixError.networkError
    }

    if !(200...299).contains(httpResponse.statusCode) {
      throw ClixError.networkError
    }
  }

  func trackEvent(name: String, properties: [String: Any]?, userId: String?) async throws {
    guard let endpoint = endpoint, let apiKey = apiKey else {
      throw ClixError.notInitialized
    }

    guard let urlComponents = URLComponents(string: "\(endpoint)/v1/events"),
      let url = urlComponents.url
    else {
      throw ClixError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")

    let body: [String: Any] = [
      "name": name,
      "properties": properties as Any,
      "userId": userId as Any,
    ]

    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    let (_, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw ClixError.networkError
    }

    if !(200...299).contains(httpResponse.statusCode) {
      throw ClixError.networkError
    }
  }

  func setAttribute(key: String, value: Any) async throws {
    guard let endpoint = endpoint, let apiKey = apiKey else {
      throw ClixError.notInitialized
    }

    guard let urlComponents = URLComponents(string: "\(endpoint)/v1/user-attributes"),
      let url = urlComponents.url
    else {
      throw ClixError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")

    let body: [String: Any] = [
      "key": key,
      "value": value,
    ]

    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    let (_, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw ClixError.networkError
    }

    if !(200...299).contains(httpResponse.statusCode) {
      throw ClixError.networkError
    }
  }
}
