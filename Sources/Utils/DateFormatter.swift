import Foundation

enum ClixDateFormatter {
  private static let iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
    formatter.timeZone = TimeZone.current
    return formatter
  }()

  static func format(_ date: Date) -> String {
    return iso8601Formatter.string(from: date)
  }
}
