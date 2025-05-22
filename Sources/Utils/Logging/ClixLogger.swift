import Foundation

class ClixLogger {
  private static var logLevel: ClixLogLevel = .info

  static func setLogLevel(_ level: ClixLogLevel) {
    logLevel = level
  }

  static func log(level: ClixLogLevel, message: String, error: Error? = nil) {
    if level.rawValue < logLevel.rawValue {
      return
    }

    let timestamp = ISO8601DateFormatter().string(from: Date())
    var logMessage = "[\(timestamp)] \(message)"
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

  static func error(_ message: String, error: Error? = nil) {
    log(level: .error, message: message, error: error)
  }

  static func warn(_ message: String, error: Error? = nil) {
    log(level: .warn, message: message, error: error)
  }

  static func info(_ message: String, error: Error? = nil) {
    log(level: .info, message: message, error: error)
  }

  static func debug(_ message: String, error: Error? = nil) {
    log(level: .debug, message: message, error: error)
  }
}
