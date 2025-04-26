import Foundation

class TokenService {
  private var currentToken: String?
  private var previousTokens: [String] = []

  func initialize() async throws {
    if let savedToken = UserDefaults.standard.string(forKey: "clix_current_token") {
      currentToken = savedToken
    }
    if let savedTokens = UserDefaults.standard.stringArray(forKey: "clix_previous_tokens") {
      previousTokens = savedTokens
    }
  }

  func getCurrentToken() -> String? {
    currentToken
  }

  func getPreviousTokens() -> [String] {
    previousTokens
  }

  func setCurrentToken(_ token: String) {
    if let currentToken = currentToken {
      previousTokens.append(currentToken)
      UserDefaults.standard.set(previousTokens, forKey: "clix_previous_tokens")
    }

    currentToken = token
    UserDefaults.standard.set(token, forKey: "clix_current_token")
  }

  func convertTokenToString(_ deviceToken: Data) -> String {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    return tokenParts.joined()
  }

  func reset() {
    currentToken = nil
    previousTokens = []
    UserDefaults.standard.removeObject(forKey: "clix_current_token")
    UserDefaults.standard.removeObject(forKey: "clix_previous_tokens")
  }
}
