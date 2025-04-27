import Foundation

public enum ClixLogLevel: Int {
  case none = 0
  case error = 1
  case warning = 2
  case info = 3
  case debug = 4
}

extension ClixLogLevel: Comparable {
  public static func < (lhs: ClixLogLevel, rhs: ClixLogLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
