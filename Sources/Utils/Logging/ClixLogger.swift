import Foundation

class ClixLogger {
  private static var logLevel: ClixLogLevel = .info

  init() {}

  static func setLogLevel(_ level: ClixLogLevel) {
    logLevel = level
  }

  static func log(level: ClixLogLevel, category: ClixLogCategory, message: String, error: Error? = nil) {
    guard level.rawValue >= logLevel.rawValue else { return }

    let timestamp = ISO8601DateFormatter().string(from: Date())
    let categoryString = String(describing: category)
    let logMessage = "[\(timestamp)] [\(categoryString)] \(message)"

    if let error = error {
      print("ERROR: \(logMessage) - Error: \(error.localizedDescription)")
    } else {
      switch level {
      case .debug:
        print("DEBUG: \(logMessage)")
      case .info:
        print("INFO: \(logMessage)")
      case .warn:
        print("WARN: \(logMessage)")
      case .error:
        print("ERROR: \(logMessage)")
      case .none:
        break
      }
    }
  }
}
