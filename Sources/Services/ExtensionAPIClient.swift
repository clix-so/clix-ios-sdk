import Foundation

/// API Client specifically designed for use in Notification Service Extensions
/// Uses shared UserDefaults to retrieve configuration values
class ExtensionAPIClient {
  private let httpClient = HTTPClient.shared
  private let baseApiPath: String = "/api/v1"
  private let appBundleId: String = Bundle.main.bundleIdentifier ?? ""

  /// Get default headers for API requests using values from shared UserDefaults
  private func getDefaultHeaders() -> [String: String] {
    let userDefaults = ClixUserDefault.shared

    var headers: [String: String] = [
      "X-Clix-Project-ID": userDefaults.getProjectId(),
      "X-Clix-API-Key": userDefaults.getApiKey(),
      "X-Clix-App-Identifier": appBundleId,
      "User-Agent": "clix-ios-sdk-extension@\(Clix.version)",
    ]

    // Add any extra headers from UserDefaults
    userDefaults.getExtraHeaders().forEach { key, value in
      headers[key] = value
    }

    return headers
  }

  /// Build URL with base endpoint from UserDefaults
  private func buildURL(path: String) throws -> URL {
    let endpoint = ClixUserDefault.shared.getEndpoint()
    guard let baseURL = URL(string: endpoint) else {
      throw ClixError.invalidURL
    }
    return baseURL.appendingPathComponent(baseApiPath + path)
  }

  /// Make a GET request
  func get<Res: Decodable>(
    path: String,
    params: [String: Any]? = nil
  ) async throws -> Res {
    let url = try buildURL(path: path)
    let headers = getDefaultHeaders()
    NSLog("[ClixNotificationServiceExtension] GET Request: URL: \(url), Params: \(params ?? [:]), Headers: \(headers)")

    do {
      let response: HTTPResponse<Res> = try await httpClient.get(url, params: params, headers: headers)
      NSLog(
        "[ClixNotificationServiceExtension] GET Response: URL: \(url), Status: \(response.statusCode), Data: \(response.data)"
      )
      return response.data
    } catch {
      NSLog(
        "[ClixNotificationServiceExtension] GET Error: URL: \(url), Params: \(params ?? [:]), Headers: \(headers), Error: \(error)"
      )
      throw error
    }
  }

  /// Make a POST request
  func post<Res: Decodable>(
    path: String,
    data: Any,
    params: [String: Any]? = nil
  ) async throws -> Res {
    let url = try buildURL(path: path)
    let headers = getDefaultHeaders()
    NSLog(
      "[ClixNotificationServiceExtension] POST Request: URL: \(url), Data: \(data), Params: \(params ?? [:]), Headers: \(headers)"
    )

    do {
      let response: HTTPResponse<Res> = try await httpClient.post(
        url,
        data: AnyCodable(data),
        params: params,
        headers: headers
      )
      NSLog(
        "[ClixNotificationServiceExtension] POST Response: URL: \(url), Status: \(response.statusCode), Data: \(response.data)"
      )
      return response.data
    } catch {
      NSLog(
        "[ClixNotificationServiceExtension] POST Error: URL: \(url), Data: \(data), Params: \(params ?? [:]), Headers: \(headers), Error: \(error)"
      )
      throw error
    }
  }

  // API client methods only - notification handling moved to ExtensionNotificationService
}
