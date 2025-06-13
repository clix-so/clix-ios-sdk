import Foundation

/// Structure that manages Clix SDK configuration
public struct ClixConfig: Codable {
  let projectId: String
  let apiKey: String
  let endpoint: String
  let logLevel: ClixLogLevel
  let extraHeaders: [String: String]

  /// Initialize ClixConfig
  /// - Parameters:
  ///   - projectId: Clix Project ID
  ///   - apiKey: Clix API key
  ///   - endpoint: Clix API endpoint URL (default: "https://api.clix.so")
  ///   - logLevel: Logging level (default: .info)
  ///   - extraHeaders: Extra headers for API requests (default: [:])
  public init(
    projectId: String = "",
    apiKey: String = "",
    endpoint: String = "https://api.clix.so",
    logLevel: ClixLogLevel = .info,
    extraHeaders: [String: String] = [:]
  ) {
    self.projectId = projectId
    self.apiKey = apiKey
    self.endpoint = endpoint
    self.logLevel = logLevel
    self.extraHeaders = extraHeaders
  }
}
