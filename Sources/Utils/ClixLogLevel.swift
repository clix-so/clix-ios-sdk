import Foundation

public enum ClixLogLevel: Int {
    case none = -1
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
}

extension ClixLogLevel: Comparable {
    public static func < (lhs: ClixLogLevel, rhs: ClixLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
