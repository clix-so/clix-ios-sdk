// APIService.swift
import Foundation

class ClixAPIClient {
  private let httpClient = HTTPClient.shared
  private let appBundleId: String = Bundle.main.bundleIdentifier ?? ""

  private func getDefaultHeaders() async throws -> [String: String] {
    [
      "X-API-Key": await Clix.shared.config.apiKey,
      "X-App-Bundle-ID": appBundleId,
      "User-Agent": "clix-ios-sdk@\(Clix.version)",
    ]
  }

  private func buildURL(path: String) async throws -> URL {
    guard let baseURL = URL(string: await Clix.shared.config.endpoint) else {
      throw ClixError.invalidURL
    }
    return baseURL.appendingPathComponent(path)
  }

  func get<Res: Decodable>(
    path: String,
    params: [String: Any]? = nil
  ) async throws -> Res {
    let url = try await buildURL(path: path)
    let headers = try await getDefaultHeaders()
    let response: HTTPResponse<Res> = try await httpClient.get(url, params: params, headers: headers)
    return response.data
  }

  func post<Res: Decodable>(
    path: String,
    data: Any,
    params: [String: Any]? = nil
  ) async throws -> Res {
    let url = try await buildURL(path: path)
    let headers = try await getDefaultHeaders()
    let response: HTTPResponse<Res> = try await httpClient.post(
      url,
      data: AnyCodable(data),
      params: params,
      headers: headers
    )
    return response.data
  }

  func put<Res: Decodable>(
    path: String,
    data: Any,
    params: [String: Any]? = nil
  ) async throws -> Res {
    let url = try await buildURL(path: path)
    let headers = try await getDefaultHeaders()
    let response: HTTPResponse<Res> = try await httpClient.put(
      url,
      data: AnyCodable(data),
      params: params,
      headers: headers
    )
    return response.data
  }

  func delete<Res: Decodable>(
    path: String,
    params: [String: Any]? = nil
  ) async throws -> Res {
    let url = try await buildURL(path: path)
    let headers = try await getDefaultHeaders()
    let response: HTTPResponse<Res> = try await httpClient.delete(
      url,
      params: params,
      headers: headers
    )
    return response.data
  }

  func download(
    path: String,
    params: [String: Any]? = nil
  ) async throws -> URL {
    let url = try await buildURL(path: path)
    let headers = try await getDefaultHeaders()
    return try await httpClient.download(url, params: params, headers: headers)
  }
}
