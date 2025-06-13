import Foundation

public enum ClixError: Error, LocalizedError {
  case notInitialized
  case invalidConfiguration
  case invalidURL
  case invalidResponse
  case networkError(Error)
  case encodingError
  case decodingError(Error)
  case unknownError(String)

  public var errorDescription: String? {
    switch self {
    case .notInitialized:
      return "Clix SDK is not initialized. Call Clix.initialize() first."
    case .invalidConfiguration:
      return "Invalid SDK configuration."

    case .invalidURL:
      return "The provided URL is invalid."
    case .invalidResponse:
      return "The response was invalid or permission was denied."
    case .networkError(let underlyingError):
      return "Network request failed: \(underlyingError.localizedDescription)"

    case .encodingError:
      return "Failed to encode request body."
    case .decodingError(let underlyingError):
      return "Failed to decode response body: \(underlyingError.localizedDescription)"

    case .unknownError(let reason):
      return "An unknown error occurred: \(reason)"
    }
  }
}

extension ClixError: Equatable {
  public static func == (lhs: ClixError, rhs: ClixError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidConfiguration, .invalidConfiguration):
      return true

    case (.networkError, .networkError):
      return lhs.localizedDescription == rhs.localizedDescription

    case (.decodingError, .decodingError):
      if case let .decodingError(lhsError) = lhs, case let .decodingError(rhsError) = rhs {
        return lhsError.localizedDescription == rhsError.localizedDescription
      }
      return false

    case (.unknownError, .unknownError):
      if case let .unknownError(lhsReason) = lhs, case let .unknownError(rhsReason) = rhs {
        return lhsReason == rhsReason
      }
      return false

    default:
      return lhs.errorDescription == rhs.errorDescription
    }
  }
}

extension ClixError: CustomStringConvertible {
  public var description: String {
    errorDescription ?? "Unknown error"
  }
}
