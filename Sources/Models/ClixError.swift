import Foundation

public enum ClixError: Error, LocalizedError {
  case notInitialized
  case invalidURL
  case invalidConfiguration(String)
  case networkError(Error?)
  case encodingError
  case decodingError(Error)
  case unknownError(Error?)
  case invalidResponse

  public var errorDescription: String? {
    switch self {
    case .notInitialized:
      return "Clix SDK is not initialized. Call Clix.configure() first."
    case .invalidURL:
      return "The provided URL is invalid."
    case .invalidConfiguration(let reason):
      return "Invalid SDK configuration: \(reason)"
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
    case .invalidResponse:
      return "The response was invalid or permission was denied."
    }
  }
}
