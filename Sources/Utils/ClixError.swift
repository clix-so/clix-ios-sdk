import Foundation

/// Represents errors that can occur in the Clix SDK
public enum ClixError: Error, LocalizedError {
  // MARK: - SDK Errors
  case notInitialized
  case invalidConfiguration(String)

  // MARK: - Network Errors
  case invalidURL
  case invalidResponse
  case networkError(Error?)

  // MARK: - Data Errors
  case encodingError
  case decodingError(Error)

  // MARK: - Unknown Error
  case unknownError(Error?)

  // MARK: - Error Description

  public var errorDescription: String? {
    switch self {
    case .notInitialized:
      return "Clix SDK is not initialized. Call Clix.initialize() first."
    case .invalidConfiguration(let reason):
      return "Invalid SDK configuration: \(reason)"

    case .invalidURL:
      return "The provided URL is invalid."
    case .invalidResponse:
      return "The response was invalid or permission was denied."
    case .networkError(let underlyingError):
      guard let error = underlyingError else {
        return "An unspecified network error occurred."
      }
      return "Network request failed: \(error.localizedDescription)"

    case .encodingError:
      return "Failed to encode request body."
    case .decodingError(let underlyingError):
      return "Failed to decode response body: \(underlyingError.localizedDescription)"

    case .unknownError(let underlyingError):
      guard let error = underlyingError else {
        return "An unknown error occurred."
      }
      return "An unknown error occurred: \(error.localizedDescription)"
    }
  }
}

// MARK: - Equatable
extension ClixError: Equatable {
  public static func == (lhs: ClixError, rhs: ClixError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidConfiguration, .invalidConfiguration):
      if case let .invalidConfiguration(lhsReason) = lhs, case let .invalidConfiguration(rhsReason) = rhs {
        return lhsReason == rhsReason
      }
      return false

    case (.networkError, .networkError):
      if case let .networkError(lhsError) = lhs, case let .networkError(rhsError) = rhs {
        return lhsError?.localizedDescription == rhsError?.localizedDescription
      }
      return false

    case (.decodingError, .decodingError):
      if case let .decodingError(lhsError) = lhs, case let .decodingError(rhsError) = rhs {
        return lhsError.localizedDescription == rhsError.localizedDescription
      }
      return false

    case (.unknownError, .unknownError):
      if case let .unknownError(lhsError) = lhs, case let .unknownError(rhsError) = rhs {
        return lhsError?.localizedDescription == rhsError?.localizedDescription
      }
      return false

    default:
      return lhs.errorDescription == rhs.errorDescription
    }
  }
}

// MARK: - CustomStringConvertible
extension ClixError: CustomStringConvertible {
  public var description: String {
    errorDescription ?? "Unknown error"
  }
}
