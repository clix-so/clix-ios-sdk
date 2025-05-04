import Foundation

class ClixLogger {
  private static var logLevel: ClixLogLevel = .info

  static func setLogLevel(_ level: ClixLogLevel) {
    logLevel = level
  }

  static func log(level: ClixLogLevel, category: ClixLogCategory, message: String, error: Error? = nil) {
    if level.rawValue < logLevel.rawValue {
      return
    }

    let timestamp = ISO8601DateFormatter().string(from: Date())
    let categoryString = String(describing: category)
    var logMessage = "[\(timestamp)] [\(categoryString)] \(message)"
    if let error = error {
      logMessage += " - Error: \(error.localizedDescription)"
    }

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
