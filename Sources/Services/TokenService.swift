import Foundation

actor TokenService {
  private let storageService: StorageService
  private let currentTokenKey = "clix_current_push_token"
  private let previousTokensKey = "clix_push_tokens"

  init(storageService: StorageService) {
    self.storageService = storageService
  }

  func getCurrentToken() async -> String? {
    await storageService.get(currentTokenKey)
  }

  func getPreviousTokens() async -> [String] {
    await storageService.get(previousTokensKey) ?? []
  }

  func saveToken(_ token: String) async {
    await storageService.set(currentTokenKey, token)

    var tokens: [String] = await storageService.get(previousTokensKey) ?? []

    if let currentIndex = tokens.firstIndex(of: token) {
      tokens.remove(at: currentIndex)
    }

    tokens.append(token)

    let maxTokens = 5
    if tokens.count > maxTokens {
      tokens = Array(tokens.suffix(maxTokens))
    }

    await storageService.set(previousTokensKey, tokens)
  }

  func clearTokens() async {
    await storageService.remove(previousTokensKey)
    await storageService.remove(currentTokenKey)
  }

  nonisolated func convertTokenToString(_ deviceToken: Data) -> String {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    return tokenParts.joined()
  }

  func reset() async {
    await clearTokens()
  }
}
