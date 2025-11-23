import Foundation

struct BundleIdentifier {
  private static let cachedBundleId: String = {
    guard let bundleId = Bundle.main.bundleIdentifier else {
      ClixLogger.warn("Bundle identifier not found, using fallback: com.clix.default")
      return "com.clix.default"
    }
    return bundleId
  }()

  static var main: String {
    cachedBundleId
  }

  static func bundleIdBasedAppGroupId(bundleId: String) -> String {
    "group.clix.\(bundleId)"
  }

  static func projectIdBasedAppGroupId(projectId: String) -> String {
    "group.clix.\(projectId)"
  }

  static func availableAppGroupId(projectId: String) -> String {
    let bundleIdBased = bundleIdBasedAppGroupId(bundleId: main)
    let projectIdBased = projectIdBasedAppGroupId(projectId: projectId)

    if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: bundleIdBased) != nil {
      ClixLogger.debug("Using bundleId-based app group: \(bundleIdBased)")
      return bundleIdBased
    }

    if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: projectIdBased) != nil {
      ClixLogger.debug("Using projectId-based app group: \(projectIdBased)")
      return projectIdBased
    }

    ClixLogger.warn("No app group found for bundleId: \(bundleIdBased) or projectId: \(projectIdBased)")
    return projectIdBased
  }
}
