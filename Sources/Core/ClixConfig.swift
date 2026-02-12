import Foundation

/// Structure that manages Clix SDK configuration
public struct ClixConfig: Codable {
  let projectId: String
  let apiKey: String
  let endpoint: String
  let logLevel: ClixLogLevel
  let extraHeaders: [String: String]
  let sessionTimeoutMs: Int

  /// Initialize ClixConfig
  /// - Parameters:
  ///   - projectId: Clix Project ID
  ///   - apiKey: Clix API key
  ///   - endpoint: Clix API endpoint URL (default: "https://api.clix.so")
  ///   - logLevel: Logging level (default: .info)
  ///   - extraHeaders: Extra headers for API requests (default: [:])
  ///   - sessionTimeoutMs: Session timeout in milliseconds (default: 30000, minimum: 5000)
  public init(
    projectId: String = "",
    apiKey: String = "",
    endpoint: String = "https://api.clix.so",
    logLevel: ClixLogLevel = .info,
    extraHeaders: [String: String] = [:],
    sessionTimeoutMs: Int = 30_000
  ) {
    self.projectId = projectId
    self.apiKey = apiKey
    self.endpoint = endpoint
    self.logLevel = logLevel
    self.extraHeaders = extraHeaders
    self.sessionTimeoutMs = sessionTimeoutMs
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    projectId = try container.decode(String.self, forKey: .projectId)
    apiKey = try container.decode(String.self, forKey: .apiKey)
    endpoint = try container.decode(String.self, forKey: .endpoint)
    logLevel = try container.decode(ClixLogLevel.self, forKey: .logLevel)
    extraHeaders = try container.decode([String: String].self, forKey: .extraHeaders)
    sessionTimeoutMs = try container.decodeIfPresent(Int.self, forKey: .sessionTimeoutMs) ?? 30_000
  }
}
