import Foundation
import Clix

enum ClixConfiguration {
  static let config: ClixConfig = {
    guard let url = Bundle.main.url(forResource: "ClixConfig", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      fatalError("Failed to load ClixConfig.json. Please ensure the file exists in Resources and contains valid JSON.")
    }

    guard let projectId = json["projectId"] as? String,
          let apiKey = json["apiKey"] as? String,
          let endpoint = json["endpoint"] as? String else {
      fatalError("ClixConfig.json is missing required fields: projectId, apiKey, or endpoint")
    }

    let extraHeaders = json["extraHeaders"] as? [String: String] ?? [:]

    return ClixConfig(
      projectId: projectId,
      apiKey: apiKey,
      endpoint: endpoint,
      logLevel: .debug,
      extraHeaders: extraHeaders
    )
  }()
}
