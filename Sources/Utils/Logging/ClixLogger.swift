import Foundation
import os

class ClixLogger {
  private static var logLevel: ClixLogLevel = .info
  private static let logger = Logger(subsystem: "so.clix.sdk", category: "ClixLogger")
  private static let dateFormatter = ISO8601DateFormatter()

  static func setLogLevel(_ level: ClixLogLevel) {
    logLevel = level
  }

  static func log(level: ClixLogLevel, message: String, error: Error? = nil) {
    if level > logLevel {
      return
    }

    let timestamp = dateFormatter.string(from: Date())
    var logMessage = "[Clix][\(timestamp)] \(message)"
    if let error = error {
      logMessage += " - Error: \(error.localizedDescription)"
    }

    switch level {
    case .debug:
      logger.debug("\(logMessage)")
    case .info:
      logger.info("\(logMessage)")
    case .warn:
      logger.warning("\(logMessage)")
    case .error:
      logger.error("\(logMessage)")
    case .none:
      return
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
