import Foundation

/// Structure that manages Clix SDK configuration
public struct ClixConfig: Encodable {
  /// Clix API key
  public let apiKey: String
  /// Clix Project ID
  public let projectId: String
  /// Clix API endpoint URL (default: "https://api.clix.so")
  public let endpoint: String
  /// Logging level setting
  public let logLevel: ClixLogLevel
  /// Extra headers for API requests
  public let extraHeaders: [String: String]

  /// Initialize ClixConfig
  /// - Parameters:
  ///   - apiKey: API key
  ///   - projectId: Project ID
  ///   - endpoint: Clix API endpoint URL (default: "https://api.clix.so")
  ///   - logLevel: Logging level (default: .info)
  ///   - extraHeaders: Extra headers for API requests (default: [:])
  public init(
    apiKey: String = "",
    projectId: String = "",
    endpoint: String = "https://api.clix.so",
    logLevel: ClixLogLevel = .info,
    extraHeaders: [String: String] = [:]
  ) {
    self.apiKey = apiKey
    self.projectId = projectId
    self.endpoint = endpoint
    self.logLevel = logLevel
    self.extraHeaders = extraHeaders
  }
}
