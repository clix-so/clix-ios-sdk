import Foundation

enum ClixLogCategory {
  case general
  case pushNotification
  case user
  case network
  case event
}

class ClixLogger {
  static let shared = ClixLogger()
  private var logLevel: ClixLogLevel = .info

  init() {}

  func setLogLevel(_ level: ClixLogLevel) {
    logLevel = level
  }

  func log(level: ClixLogLevel, category: ClixLogCategory, message: String, error: Error? = nil) {
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
      case .warning:
        print("WARNING: \(logMessage)")
      case .error:
        print("ERROR: \(logMessage)")
      case .none:
        break
      }
    }
  }
}
