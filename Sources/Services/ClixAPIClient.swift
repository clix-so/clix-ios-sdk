import Foundation

class ClixAPIClient {
  private let httpClient = HTTPClient.shared
  private let appBundleId: String = Bundle.main.bundleIdentifier ?? ""
  private let baseApiPath: String = "/api/v1"
  private let config: ClixConfig?

  init() {
    self.config = nil
  }

  init(config: ClixConfig) {
    self.config = config
  }

  private func getEnvironment() throws -> ClixEnvironment {
    do {
      return try Clix.shared.get(\.environment)
    } catch {
      throw ClixError.invalidResponse
    }
  }

  private func getDefaultHeaders() throws -> [String: String] {
    let clixConfig: ClixConfig

    if let config = self.config {
      clixConfig = config
    } else {
      let environment = try getEnvironment()
      clixConfig = environment.config
    }

    var headers: [String: String] = [
      "X-Clix-Project-ID": clixConfig.projectId,
      "X-Clix-API-Key": clixConfig.apiKey,
      "X-Clix-App-Identifier": appBundleId,
      "User-Agent": "clix-ios-sdk@\(Clix.version)",
    ]

    clixConfig.extraHeaders.forEach { key, value in
      headers[key] = value
    }

    return headers
  }

  private func buildURL(path: String) throws -> URL {
    let endpoint: String

    if let config = self.config {
      endpoint = config.endpoint
    } else {
      let environment = try getEnvironment()
      endpoint = environment.config.endpoint
    }

    guard let baseURL = URL(string: endpoint) else {
      throw ClixError.invalidURL
    }
    return baseURL.appendingPathComponent(baseApiPath + path)
  }

  func get<Res: Decodable>(
    path: String,
    params: [String: Any]? = nil
  ) async throws -> Res {
    let url = try buildURL(path: path)
    let headers = try getDefaultHeaders()
    ClixLogger.debug("GET Request: URL: \(url), Params: \(params ?? [:]), Headers: \(headers)")
    do {
      let response: HTTPResponse<Res> = try await httpClient.get(url, params: params, headers: headers)
      ClixLogger.debug(
        "GET Response: URL: \(url), Status: \(response.statusCode), Data: \(response.data)"
      )
      return response.data
    } catch {
      ClixLogger.error(
        "GET Error: URL: \(url), Params: \(params ?? [:]), Headers: \(headers), Error: \(error)"
      )
      throw error
    }
  }

  func post<Res: Decodable>(
    path: String,
    data: Any,
    params: [String: Any]? = nil
  ) async throws -> Res {
    let url = try buildURL(path: path)
    let headers = try getDefaultHeaders()
    ClixLogger.debug("POST Request: URL: \(url), Data: \(data), Params: \(params ?? [:]), Headers: \(headers)")

    do {
      let response: HTTPResponse<Res> = try await httpClient.post(
        url,
        data: AnyCodable(data),
        params: params,
        headers: headers
      )
      ClixLogger.debug("POST Response: URL: \(url), Status: \(response.statusCode), Data: \(response.data)")
      return response.data
    } catch {
      ClixLogger.error(
        "POST Error: URL: \(url), Data: \(data), Params: \(params ?? [:]), Headers: \(headers), Error: \(error)"
      )
      throw error
    }
  }

  func delete<Res: Decodable>(
    path: String,
    params: [String: Any]? = nil
  ) async throws -> Res {
    let url = try buildURL(path: path)
    let headers = try getDefaultHeaders()
    ClixLogger.debug("DELETE Request: URL: \(url), Params: \(params ?? [:]), Headers: \(headers)")

    do {
      let response: HTTPResponse<Res> = try await httpClient.delete(
        url,
        params: params,
        headers: headers
      )
      ClixLogger.debug("DELETE Response: URL: \(url), Status: \(response.statusCode), Data: \(response.data)")
      return response.data
    } catch {
      ClixLogger.error(
        "DELETE Error: URL: \(url), Params: \(params ?? [:]), Headers: \(headers), Error: \(error)"
      )
      throw error
    }
  }

  func download(
    path: String,
    params: [String: Any]? = nil
  ) async throws -> URL {
    let url = try buildURL(path: path)
    let headers = try getDefaultHeaders()
    ClixLogger.debug("DOWNLOAD Request: URL: \(url), Params: \(params ?? [:]), Headers: \(headers)")
    do {
      let downloadedURL = try await httpClient.download(url, params: params, headers: headers)
      ClixLogger.debug("DOWNLOAD Response: URL: \(url), Downloaded File URL: \(downloadedURL)")
      return downloadedURL
    } catch {
      ClixLogger.error(
        "DOWNLOAD Error: URL: \(url), Params: \(params ?? [:]), Headers: \(headers), Error: \(error)"
      )
      throw error
    }
  }
}
