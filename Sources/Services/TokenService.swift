import Foundation

actor TokenService {
  private let storageService: StorageService
  private let currentTokenKey = "clix_current_token"
  private let previousTokensKey = "clix_previous_tokens"

  init(storageService: StorageService = StorageService()) {
    self.storageService = storageService
  }

  /// Get the current token
  /// - Returns: Current token if exists, nil otherwise
  func getCurrentToken() async -> String? {
    await storageService.get(forKey: currentTokenKey)
  }

  /// Get previous tokens
  /// - Returns: Array of previous tokens
  func getPreviousTokens() async -> [String] {
    await storageService.get(forKey: previousTokensKey) ?? []
  }

  /// Save a new token
  /// - Parameter token: Token to save
  func saveToken(_ token: String) async {
    var previousTokens = await getPreviousTokens()

    // Add current token to previous tokens if it exists
    if let currentToken = await getCurrentToken() {
      previousTokens.append(currentToken)
    }

    // Keep only last 5 tokens
    if previousTokens.count > 5 {
      previousTokens = Array(previousTokens.suffix(5))
    }

    // Save previous tokens
    await storageService.set(previousTokens, forKey: previousTokensKey)

    // Save new token
    await storageService.set(token, forKey: currentTokenKey)
  }

  /// Clear all tokens
  func clearTokens() async {
    await storageService.remove(forKey: currentTokenKey)
    await storageService.remove(forKey: previousTokensKey)
  }

  func convertTokenToString(_ deviceToken: Data) -> String {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    return tokenParts.joined()
  }

  func reset() async {
    await clearTokens()
  }
}
