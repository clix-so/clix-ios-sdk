import Foundation
import Clix

public final class ClixConfiguration {
  public static let shared = ClixConfiguration()

  private init() {
    self.cached = Self.load()
  }

  private static func load() -> [String: Any] {
    guard let url = Bundle.main.url(forResource: "ClixConfig", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      fatalError("Failed to load ClixConfig.json")
    }
    return json
  }

  private let cached: [String: Any]

  public lazy var projectId: String = cached["projectId"] as? String ?? ""

  public lazy var apiKey: String = cached["apiKey"] as? String ?? ""

  public lazy var endpoint: String = cached["endpoint"] as? String ?? ""

  public lazy var logLevel: ClixLogLevel = .debug

  public lazy var extraHeaders: [String: String] = cached["extraHeaders"] as? [String: String] ?? [:]

  public var config: ClixConfig {
    ClixConfig(
      projectId: projectId,
      apiKey: apiKey,
      endpoint: endpoint,
      logLevel: logLevel,
      extraHeaders: extraHeaders
    )
  }
}
