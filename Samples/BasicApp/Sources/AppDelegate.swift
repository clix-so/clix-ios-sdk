import UIKit
import UserNotifications
import Clix
import Firebase

class AppDelegate: ClixAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()
    Task {
      do {
        try await Clix.initialize(
          config: ClixConfig(
            apiKey: "YOUR_API_KEY",
            projectId: "78840003-2024-4116-a843-9438aefd3205",
            endpoint: "https://external-api-dev.clix.so",
            logLevel: .debug,
            extraHeaders: [
              "cf-access-token":
                "eyJhbGciOiJSUzI1NiIsImtpZCI6IjA3MzY1NmRiYjM2NWY1NjM0MDgzNjIzNzM4OTgzYmI3NTQ4NjkyZDJlMjNkMGNiNDgxMjQxZGQxZjI5Yjg1NzQifQ."
                + "eyJhdWQiOlsiODAzYjE3NDhhOTVlNzc5YjMyOTMxYjZlNjlmMDhjMjNhYTUzNTAwMDc0YmE2YmQ4ZjVhODg4MTg5YWU2ZTYwMCJdLCJlbWFpbCI6Im1pbmt5dUBncmV5Ym94aHEuY29tIiwiZXhwIjoxNzQ4NTc2Njc3LCJpYXQiOjE3NDc5NzE4NzcsIm5iZiI6MTc0Nzk3MTg3NywiaXNzIjoiaHR0cHM6Ly9ncmV5Ym94LmNsb3VkZmxhcmVhY2Nlc3MuY29tIiwidHlwZSI6ImFwcCIsImlkZW50aXR5X25vbmNlIjoiak5vemJqY0M2UFBiNU00dCIsInN1YiI6IjRlOWI2ZjdjLTI0Y2ItNTlkNy1hZDE4LTM2MDg3MzA3MzQ1MiIsImNvdW50cnkiOiJLUiJ9."
                + "pT9Nf5uWua4NGIAkxVyGk9cgV4qWak10FKyd_8IKkeRenTaLSuFaE1mhfDWQrGbHvq7EOoPJjmRZtgOzida61WAKeWqG0zX_"
                + "yr-oxeYVezTiSQCd_h_m91ENTjkYTVQiemffNGklp4sWxyG9X-P5hZQdvuiuGD2kTcXPKib7uLKdqp50qdO717pRnVH5nE1dE5"
                + "1sSgR4VeOLkuUP7uiVs74R62WnQnffzc8HP5uEf8iaAfXUGM-hypDSCNM9twWxn0jYdPAzZ6PKABpRWc4F7RyX5hBxAiMj8weal"
                + "6fmg5O6lACeEAbjOZBCYx5b9E7Uh086SOmKD5rYhCOh4Ok2Pw"
            ]
          )
        )
        print("✅ Clix SDK initialized")
      } catch {
        print("❌ Clix SDK failed to initialize:", error)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
