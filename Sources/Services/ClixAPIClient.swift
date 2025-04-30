// APIService.swift
import Foundation

class ClixAPIClient {
  private let httpClient: HTTPClient
  private let apiKey: String
  private let appBundleId: String
  private let baseURL: URL

  init() throws {
    self.httpClient = HTTPClient()
    self.apiKey = try Clix.getShared().config.apiKey
    self.appBundleId = Bundle.main.bundleIdentifier ?? ""
    guard let baseURL = URL(string: try Clix.getShared().config.endpoint) else {
      throw ClixError.invalidURL
    }
    self.baseURL = baseURL
  }

  private func getDefaultHeaders() throws -> [String: String] {
    [
      "X-API-Key": apiKey,
      "X-App-Bundle-ID": appBundleId,
    ]
  }

  func get<Res: Decodable>(
    path: String,
    params: [String: Any]? = nil
  ) async throws -> HTTPResponse<Res> {
    let url = baseURL.appendingPathComponent(path)
    return try await httpClient.get(url, params: params, headers: try getDefaultHeaders())
  }

  func post<Res: Decodable>(
    path: String,
    data: AnyCodable,
    params: [String: Any]? = nil
  ) async throws -> HTTPResponse<Res> {
    let url = baseURL.appendingPathComponent(path)
    return try await httpClient.post(
      url,
      data: data,
      params: params,
      headers: try getDefaultHeaders()
    )
  }

  func put<Res: Decodable>(
    path: String,
    data: AnyCodable,
    params: [String: Any]? = nil
  ) async throws -> HTTPResponse<Res> {
    let url = baseURL.appendingPathComponent(path)
    return try await httpClient.put(
      url,
      data: data,
      params: params,
      headers: try getDefaultHeaders()
    )
  }

  func delete<Res: Decodable>(
    path: String,
    params: [String: Any]? = nil
  ) async throws -> HTTPResponse<Res> {
    let url = baseURL.appendingPathComponent(path)
    return try await httpClient.delete(
      url,
      params: params,
      headers: try getDefaultHeaders()
    )
  }

  func download(
    path: String,
    params: [String: Any]? = nil
  ) async throws -> URL {
    let url = baseURL.appendingPathComponent(path)
    return try await httpClient.download(url, params: params, headers: try getDefaultHeaders())
  }
}
