import ActivityKit
import Foundation

@available(iOS 16.2, *)
@MainActor
class LiveActivityManager: ObservableObject {
  static let shared = LiveActivityManager()

  @Published var isActive: Bool = false
  private var currentActivity: Activity<DeliveryActivityAttributes>?

  private init() {}

  func start() {
    let attributes = DeliveryActivityAttributes(
      orderNumber: String(Int.random(in: 1000...9999)),
      restaurantName: "Pizza Palace"
    )
    let contentState = DeliveryActivityAttributes.ContentState(
      status: "Preparing",
      estimatedDeliveryTime: "30-40 min"
    )

    do {
      let activity = try Activity<DeliveryActivityAttributes>.request(
        attributes: attributes,
        content: .init(state: contentState, staleDate: nil),
        pushType: .token
      )
      currentActivity = activity
      isActive = true
      print("Live Activity started: \(activity.id)")
    } catch {
      print("Failed to start Live Activity: \(error)")
    }
  }

  func update(status: String) {
    guard let activity = currentActivity else { return }

    let estimatedTime: String
    switch status {
    case "Preparing":
      estimatedTime = "30-40 min"
    case "On the way":
      estimatedTime = "10-15 min"
    case "Delivered":
      estimatedTime = "Arrived!"
    default:
      estimatedTime = "Unknown"
    }

    let contentState = DeliveryActivityAttributes.ContentState(
      status: status,
      estimatedDeliveryTime: estimatedTime
    )

    Task {
      await activity.update(ActivityContent(state: contentState, staleDate: nil))
      print("Live Activity updated: \(status)")
    }
  }

  func end() {
    guard let activity = currentActivity else { return }

    Task {
      await activity.end(nil, dismissalPolicy: .immediate)
      await MainActor.run {
        currentActivity = nil
        isActive = false
      }
      print("Live Activity ended")
    }
  }
}
