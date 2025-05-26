// APIService.swift
import Foundation

class ClixAPIClient {
  private let httpClient = HTTPClient.shared
  private let appBundleId: String = Bundle.main.bundleIdentifier ?? ""
  private let baseApiPath: String = "/api/v1"

  private func getDefaultHeaders() async throws -> [String: String] {
    let config = await Clix.shared.config
    var headers: [String: String] = [
      "X-Clix-Project-ID": config.projectId,
      "X-Clix-API-Key": config.apiKey,
      "X-Clix-App-Identifier": appBundleId,
      "User-Agent": "clix-ios-sdk@\(Clix.version)",
    ]
    config.extraHeaders.forEach { key, value in
      headers[key] = value
    }
    return headers
  }

  private func buildURL(path: String) async throws -> URL {
    guard let baseURL = URL(string: await Clix.shared.config.endpoint) else {
      throw ClixError.invalidURL
    }
    return baseURL.appendingPathComponent(baseApiPath + path)
  }

  func get<Res: Decodable>(
    path: String,
    params: [String: Any]? = nil
  ) async throws -> Res {
    let url = try await buildURL(path: path)
    let headers = try await getDefaultHeaders()
    ClixLogger.debug("ClixAPIClient GET Request: URL: \(url), Params: \(params ?? [:]), Headers: \(headers)")
    do {
      let response: HTTPResponse<Res> = try await httpClient.get(url, params: params, headers: headers)
      ClixLogger.debug(
        "ClixAPIClient GET Response: URL: \(url), Status: \(response.statusCode), Data: \(response.data)"
      )
      return response.data
    } catch {
      ClixLogger.error(
        "ClixAPIClient GET Error: URL: \(url), Params: \(params ?? [:]), Headers: \(headers), Error: \(error)"
      )
      throw error
    }
  }

  func post<Res: Decodable>(
    path: String,
    data: Any,
    params: [String: Any]? = nil
  ) async throws -> Res {
    let url = try await buildURL(path: path)
    let headers = try await getDefaultHeaders()
    ClixLogger.debug(
      "ClixAPIClient POST Request: URL: \(url), Data: \(data), Params: \(params ?? [:]), Headers: \(headers)"
    )
    do {
      let response: HTTPResponse<Res> = try await httpClient.post(
        url,
        data: AnyCodable(data),
        params: params,
        headers: headers
      )
      ClixLogger.debug(
        "ClixAPIClient POST Response: URL: \(url), Status: \(response.statusCode), Data: \(response.data)"
      )
      return response.data
    } catch {
      ClixLogger.error(
        "ClixAPIClient POST Error: URL: \(url), Data: \(data), Params: \(params ?? [:]), Headers: \(headers), Error: \(error)"
      )
      throw error
    }
  }

  func put<Res: Decodable>(
    path: String,
    data: Any,
    params: [String: Any]? = nil
  ) async throws -> Res {
    let url = try await buildURL(path: path)
    let headers = try await getDefaultHeaders()
    ClixLogger.debug(
      "ClixAPIClient PUT Request: URL: \(url), Data: \(data), Params: \(params ?? [:]), Headers: \(headers)"
    )
    do {
      let response: HTTPResponse<Res> = try await httpClient.put(
        url,
        data: AnyCodable(data),
        params: params,
        headers: headers
      )
      ClixLogger.debug(
        "ClixAPIClient PUT Response: URL: \(url), Status: \(response.statusCode), Data: \(response.data)"
      )
      return response.data
    } catch {
      ClixLogger.error(
        "ClixAPIClient PUT Error: URL: \(url), Data: \(data), Params: \(params ?? [:]), Headers: \(headers), Error: \(error)"
      )
      throw error
    }
  }

  func delete<Res: Decodable>(
    path: String,
    params: [String: Any]? = nil
  ) async throws -> Res {
    let url = try await buildURL(path: path)
    let headers = try await getDefaultHeaders()
    ClixLogger.debug("ClixAPIClient DELETE Request: URL: \(url), Params: \(params ?? [:]), Headers: \(headers)")
    do {
      let response: HTTPResponse<Res> = try await httpClient.delete(
        url,
        params: params,
        headers: headers
      )
      ClixLogger.debug(
        "ClixAPIClient DELETE Response: URL: \(url), Status: \(response.statusCode), Data: \(response.data)"
      )
      return response.data
    } catch {
      ClixLogger.error(
        "ClixAPIClient DELETE Error: URL: \(url), Params: \(params ?? [:]), Headers: \(headers), Error: \(error)"
      )
      throw error
    }
  }

  func download(
    path: String,
    params: [String: Any]? = nil
  ) async throws -> URL {
    let url = try await buildURL(path: path)
    let headers = try await getDefaultHeaders()
    ClixLogger.debug("ClixAPIClient DOWNLOAD Request: URL: \(url), Params: \(params ?? [:]), Headers: \(headers)")
    do {
      let downloadedURL = try await httpClient.download(url, params: params, headers: headers)
      ClixLogger.debug("ClixAPIClient DOWNLOAD Response: URL: \(url), Downloaded File URL: \(downloadedURL)")
      return downloadedURL
    } catch {
      ClixLogger.error(
        "ClixAPIClient DOWNLOAD Error: URL: \(url), Params: \(params ?? [:]), Headers: \(headers), Error: \(error)"
      )
      throw error
    }
  }
}
