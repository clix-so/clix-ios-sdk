import SwiftUI

struct ContentView: View {
  @State private var userIdInput: String = ""
  let projectIdText = "N/A"
  let apiKeyText = "N/A"
  let deviceIdText = "N/A"
  let fcmTokenText = "N/A"

  @State private var showAlert = false
  @State private var alertMessage = ""

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        Image("Logo")
          .resizable()
          .frame(width: 120, height: 120)
          .padding(.bottom, 32)

        VStack(spacing: 0) {
          InfoTextRow(
            label: NSLocalizedString("project_id", comment: ""),
            value: projectIdText
          )
          InfoTextRow(
            label: NSLocalizedString("api_key", comment: ""),
            value: apiKeyText
          )
          InfoTextRow(
            label: NSLocalizedString("device_id", comment: ""),
            value: deviceIdText
          )
          InfoTextRow(
            label: NSLocalizedString("fcm_token", comment: ""),
            value: fcmTokenText,
            lastItem: true
          )

          Spacer().frame(height: 32)

          HStack {
            TextField(
              NSLocalizedString("user_id", comment: ""),
              text: $userIdInput
            )
            .padding()
            .background(AppTheme.surfaceVariant.opacity(0.5))
            .cornerRadius(12)
            .foregroundColor(AppTheme.text)
            .frame(height: 56)
            Spacer().frame(width: 12)
            Button(action: {
              if !userIdInput.isEmpty {
                alertMessage = "User ID set!"
              } else {
                alertMessage = "Please enter a User ID"
              }
              showAlert = true
            }) {
              Text(NSLocalizedString("submit", comment: ""))
                .fontWeight(.bold)
                .foregroundColor(AppTheme.buttonText)
                .frame(maxHeight: .infinity)
            }
            .frame(height: 56)
            .padding(.horizontal, 12)
            .background(AppTheme.buttonBackground)
            .cornerRadius(12)
          }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(AppTheme.surface.opacity(0.8))
        .cornerRadius(18)
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 16)
    }
    .background(AppTheme.background.ignoresSafeArea())
    .alert(isPresented: $showAlert) {
      Alert(title: Text(alertMessage))
    }
  }
}

struct InfoTextRow: View {
  let label: String
  let value: String
  var lastItem: Bool = false

  var body: some View {
    Text("\(label) \(value)")
      .foregroundColor(AppTheme.text)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.bottom, lastItem ? 0 : 12)
      .font(.system(size: 16))
  }
}
