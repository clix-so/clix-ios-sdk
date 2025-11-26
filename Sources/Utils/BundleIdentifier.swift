import Foundation

struct BundleIdentifier {
  private static let defaultBundleId = "com.clix.default"
  private static let appGroupPrefix = "group.clix."

  private static let cachedBundleId: String = {
    resolvePrimaryBundleIdentifier() ?? defaultBundleId
  }()

  static var main: String { cachedBundleId }

  static func bundleIdBasedAppGroupId(bundleId: String) -> String {
    "\(appGroupPrefix)\(bundleId)"
  }

  static func projectIdBasedAppGroupId(projectId: String) -> String {
    "\(appGroupPrefix)\(projectId)"
  }

  static func availableAppGroupId(projectId: String) -> String {
    let bundleIdBased = bundleIdBasedAppGroupId(bundleId: main)
    let projectIdBased = projectIdBasedAppGroupId(projectId: projectId)

    if isAppGroupAvailable(bundleIdBased) {
      return bundleIdBased
    }

    if isAppGroupAvailable(projectIdBased) {
      return projectIdBased
    }

    ClixLogger.warn("No app group found: \(bundleIdBased), \(projectIdBased)")
    return projectIdBased
  }

  private static func resolvePrimaryBundleIdentifier() -> String? {
    let bundle = Bundle.main

    if isAppExtension(bundle) {
      return resolveMainAppBundleIdentifier(from: bundle)
    }

    return bundle.bundleIdentifier
  }

  private static func isAppExtension(_ bundle: Bundle) -> Bool {
    bundle.bundleURL.pathExtension == "appex"
  }

  private static func resolveMainAppBundleIdentifier(from extensionBundle: Bundle) -> String? {
    let mainAppURL = extensionBundle.bundleURL
      .deletingLastPathComponent()
      .deletingLastPathComponent()

    return Bundle(url: mainAppURL)?.bundleIdentifier
  }

  private static func isAppGroupAvailable(_ identifier: String) -> Bool {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) != nil
  }
}
