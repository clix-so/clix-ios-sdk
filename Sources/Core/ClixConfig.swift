import Foundation

/// Structure that manages Clix SDK configuration
public struct ClixConfig {
  /// Logging level setting
  public let logLevel: ClixLogLevel

  /// Initialize ClixConfig
  /// - Parameters:
  ///   - logLevel: Logging level (default: .info)
  public init(
    logLevel: ClixLogLevel = .info
  ) {
    self.logLevel = logLevel
  }
}
