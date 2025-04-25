import Foundation

class ClixNetworkManager {
  static let shared = ClixNetworkManager()

  private let session: URLSession
  private var config: ClixConfig?

  init() {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 300
    self.session = URLSession(configuration: config)
  }

  func configure(with config: ClixConfig) {
    self.config = config
  }

  func registerDevice(token: String, userId: String?) async throws {
    guard let config = config else {
      throw ClixError.notInitialized
    }

    guard let urlComponents = URLComponents(string: "\(config.endpoint)/v1/devices"),
      let url = urlComponents.url
    else {
      throw ClixError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")

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
    guard let config = config else {
      throw ClixError.notInitialized
    }

    guard let urlComponents = URLComponents(string: "\(config.endpoint)/v1/events"),
      let url = urlComponents.url
    else {
      throw ClixError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")

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
    guard let config = config else {
      throw ClixError.notInitialized
    }

    let urlComponents = URLComponents(string: "\(config.endpoint)/v1/attributes")
    guard let url = urlComponents?.url else {
      throw ClixError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")

    let body: [String: Any] = [
      "key": key,
      "value": value,
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (_, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw ClixError.invalidResponse
    }

    if !(200...299).contains(httpResponse.statusCode) {
      throw ClixError.serverError(statusCode: httpResponse.statusCode)
    }
  }
}
