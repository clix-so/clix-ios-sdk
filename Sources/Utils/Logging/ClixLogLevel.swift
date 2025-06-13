import Foundation

/// The log level for Clix.
public enum ClixLogLevel: Int, Codable {
  /// No logs.
  case none = 0
  /// Error logs.
  case error = 1
  /// Warning logs.
  case warn = 2
  /// Info logs.
  case info = 3
  /// Debug logs.
  case debug = 4
}

extension ClixLogLevel: Comparable {
  public static func < (lhs: ClixLogLevel, rhs: ClixLogLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
