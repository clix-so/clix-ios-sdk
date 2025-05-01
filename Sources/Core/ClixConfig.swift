import Foundation

/// Structure that manages Clix SDK configuration
public struct ClixConfig {
  /// Clix API key
  public let apiKey: String
  /// Clix API endpoint URL (default: "https://api.clix.io")
  public let endpoint: String
  /// Logging level setting
  public let logLevel: ClixLogLevel

  /// Initialize ClixConfig
  /// - Parameters:
  ///   - apiKey: API key
  ///   - endpoint: Clix API endpoint URL (default: "https://api.clix.io")
  ///   - logLevel: Logging level (default: .info)
  public init(
    apiKey: String = "",
    endpoint: String = "https://api.clix.io",
    logLevel: ClixLogLevel = .info
  ) {
    self.apiKey = apiKey
    self.endpoint = endpoint
    self.logLevel = logLevel
  }
}
