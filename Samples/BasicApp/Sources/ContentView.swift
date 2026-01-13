import Clix
import SwiftUI

struct ContentView: View {
  @ObservedObject private var appState = AppState.shared

  @State private var userIdInput: String = UserDefaults.standard.string(forKey: "user_id") ?? ""

  @State private var userPropertyKeyInput: String = ""
  @State private var userPropertyValueInput: String = ""

  @State private var eventNameInput: String = "test"
  @State private var eventParamsInput: String = """
    {
      "string": "string",
      "number": 1.5,
      "boolean": true,
      "object": { "key": "value" }
    }
    """

  @State private var showAlert: Bool = false
  @State private var alertMessage: String = ""

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
            value: ClixConfiguration.shared.projectId
          )
          InfoTextRow(
            label: NSLocalizedString("api_key", comment: ""),
            value: ClixConfiguration.shared.apiKey
          )
          InfoTextRow(
            label: NSLocalizedString("device_id", comment: ""),
            value: appState.deviceId
          )
          InfoTextRow(
            label: NSLocalizedString("push_token", comment: ""),
            value: appState.fcmToken,
            lastItem: true
          )

          Spacer().frame(height: 32)

          HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
              Text(NSLocalizedString("user_id", comment: ""))
                .font(.system(size: 14))
                .foregroundColor(AppTheme.text)
              TextField("", text: $userIdInput)
                .padding()
                .background(AppTheme.surfaceVariant.opacity(0.5))
                .cornerRadius(12)
                .foregroundColor(AppTheme.text)
                .frame(height: 56)
            }
            Spacer().frame(width: 12)
            Button(
              action: {
                if !userIdInput.isEmpty {
                  UserDefaults.standard.set(userIdInput, forKey: "user_id")
                  Clix.setUserId(userIdInput)
                  alertMessage = "User ID set!"
                } else {
                  alertMessage = "Please enter a User ID"
                }
                showAlert = true
              },
              label: {
                Text(NSLocalizedString("submit", comment: ""))
                  .fontWeight(.bold)
                  .foregroundColor(AppTheme.buttonText)
                  .frame(maxHeight: .infinity)
              }
            )
            .frame(height: 56)
            .padding(.horizontal, 12)
            .background(AppTheme.buttonBackground)
            .cornerRadius(12)
          }

          Spacer().frame(height: 32)

          VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
              Text(NSLocalizedString("user_property_key", comment: ""))
                .font(.system(size: 14))
                .foregroundColor(AppTheme.text)
              TextField("", text: $userPropertyKeyInput)
                .padding()
                .background(AppTheme.surfaceVariant.opacity(0.5))
                .cornerRadius(12)
                .foregroundColor(AppTheme.text)
                .frame(height: 56)
            }

            VStack(alignment: .leading, spacing: 4) {
              Text(NSLocalizedString("user_property_value", comment: ""))
                .font(.system(size: 14))
                .foregroundColor(AppTheme.text)
              TextField("", text: $userPropertyValueInput)
                .padding()
                .background(AppTheme.surfaceVariant.opacity(0.5))
                .cornerRadius(12)
                .foregroundColor(AppTheme.text)
                .frame(height: 56)
            }

            Button(
              action: {
                guard !userPropertyKeyInput.isEmpty && !userPropertyValueInput.isEmpty else {
                  alertMessage = "Please enter both key and value for user property"
                  showAlert = true
                  return
                }

                Clix.setUserProperty(userPropertyKeyInput, value: userPropertyValueInput)
                alertMessage = "User property '\(userPropertyKeyInput): \(userPropertyValueInput)' set successfully"
                showAlert = true

                userPropertyKeyInput = ""
                userPropertyValueInput = ""
              },
              label: {
                Text(NSLocalizedString("set_user_property", comment: ""))
                  .fontWeight(.bold)
                  .foregroundColor(AppTheme.buttonText)
                  .frame(maxHeight: .infinity)
              }
            )
            .frame(height: 56)
            .padding(.horizontal, 12)
            .background(AppTheme.buttonBackground)
            .cornerRadius(12)
          }

          Spacer().frame(height: 32)

          VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
              Text(NSLocalizedString("event_name", comment: ""))
                .font(.system(size: 14))
                .foregroundColor(AppTheme.text)
              TextField("", text: $eventNameInput)
                .padding()
                .background(AppTheme.surfaceVariant.opacity(0.5))
                .cornerRadius(12)
                .foregroundColor(AppTheme.text)
                .frame(height: 56)
            }

            VStack(alignment: .leading, spacing: 4) {
              Text(NSLocalizedString("event_params", comment: ""))
                .font(.system(size: 14))
                .foregroundColor(AppTheme.text)
              Group {
                if #available(iOS 16.0, *) {
                  TextEditor(text: $eventParamsInput)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                } else {
                  TextEditor(text: $eventParamsInput)
                    .background(.clear)
                }
              }
              .padding()
              .background(AppTheme.surfaceVariant.opacity(0.5))
              .cornerRadius(12)
              .foregroundColor(AppTheme.text)
              .frame(minHeight: 120)
            }

            Button(
              action: {
                guard !eventNameInput.isEmpty else {
                  alertMessage = "Please enter an event name"
                  showAlert = true
                  return
                }

                var properties: [String: Any?] = [:]
                if !eventParamsInput.isEmpty && eventParamsInput != "{}" {
                  if let data = eventParamsInput.data(using: .utf8) {
                    do {
                      if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        properties = json
                      }
                    } catch {
                      alertMessage = "Invalid JSON format"
                      showAlert = true
                      return
                    }
                  }
                }

                Clix.trackEvent(eventNameInput, properties: properties)
                alertMessage = "Event tracked: \(eventNameInput)"
                showAlert = true
              },
              label: {
                Text(NSLocalizedString("track_event", comment: ""))
                  .fontWeight(.bold)
                  .foregroundColor(AppTheme.buttonText)
                  .frame(maxHeight: .infinity)
              }
            )
            .frame(height: 56)
            .padding(.horizontal, 12)
            .background(AppTheme.buttonBackground)
            .cornerRadius(12)
          }

          Spacer().frame(height: 32)

          if #available(iOS 16.2, *) {
            LiveActivitySection()
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

@available(iOS 16.2, *)
struct LiveActivitySection: View {
  @ObservedObject private var manager = LiveActivityManager.shared
  @State private var deliveryStatus: String = "Preparing"

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Live Activity")
        .font(.headline)
        .foregroundColor(AppTheme.text)

      if !manager.isActive {
        Button(action: { manager.start() }) {
          Text("Start Live Activity")
            .fontWeight(.bold)
            .foregroundColor(AppTheme.buttonText)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .background(AppTheme.buttonBackground)
        .cornerRadius(12)
      } else {
        Picker("Status", selection: $deliveryStatus) {
          Text("Preparing").tag("Preparing")
          Text("On the way").tag("On the way")
          Text("Delivered").tag("Delivered")
        }
        .pickerStyle(SegmentedPickerStyle())

        Button(action: { manager.update(status: deliveryStatus) }) {
          Text("Update Status")
            .fontWeight(.bold)
            .foregroundColor(AppTheme.buttonText)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .background(AppTheme.buttonBackground)
        .cornerRadius(12)

        Button(action: { manager.end() }) {
          Text("End Live Activity")
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .background(Color.red)
        .cornerRadius(12)
      }
    }
  }
}

struct InfoTextRow: View {
  let label: String
  let value: String
  var lastItem: Bool = false

  var body: some View {
    Text("\(label): \(value)")
      .foregroundColor(AppTheme.text)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.bottom, lastItem ? 0 : 12)
      .font(.system(size: 16))
  }
}
