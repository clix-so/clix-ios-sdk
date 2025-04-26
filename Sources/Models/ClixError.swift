import Foundation

public enum ClixError: Error {
  case notInitialized
  case networkError
  case invalidToken
  case invalidUserId
  case invalidAttribute
  case invalidEvent
  case invalidURL
  case invalidResponse
  case serverError(statusCode: Int)
}

extension ClixError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .notInitialized:
      return "Clix is not initialized. Please call Clix.initialize() first."
    case .networkError:
      return "Network error. Please check your internet connection."
    case .invalidToken:
      return "Invalid device token."
    case .invalidUserId:
      return "Invalid user ID. Please call Clix.setUserId() first."
    case .invalidAttribute:
      return "Invalid attribute. Please check the attribute format."
    case .invalidEvent:
      return "Invalid event. Please check the event format."
    case .invalidURL:
      return "Invalid URL. Please check the URL format."
    case .invalidResponse:
      return "Invalid response from server."
    case .serverError(let statusCode):
      return "Server error with status code: \(statusCode)"
    }
  }
}
