import ActivityKit
import SwiftUI
import WidgetKit

struct DeliveryLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: DeliveryActivityAttributes.self) { context in
      // Lock screen / banner UI
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Image(systemName: "bag.fill")
            .foregroundColor(.orange)
          Text(context.attributes.restaurantName)
            .font(.headline)
            .fontWeight(.semibold)
          Spacer()
          Text("Order #\(context.attributes.orderNumber)")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(context.state.status)
              .font(.subheadline)
              .fontWeight(.medium)
            Text(context.state.estimatedDeliveryTime)
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Spacer()
          Image(systemName: statusIcon(for: context.state.status))
            .font(.title)
            .foregroundColor(.orange)
        }
      }
      .padding()
      .background(Color(.systemBackground))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: "bag.fill")
            .foregroundColor(.orange)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Image(systemName: statusIcon(for: context.state.status))
            .foregroundColor(.orange)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(context.attributes.restaurantName)
            .font(.headline)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(spacing: 4) {
            Text(context.state.status)
              .font(.subheadline)
            Text(context.state.estimatedDeliveryTime)
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      } compactLeading: {
        Image(systemName: "bag.fill")
          .foregroundColor(.orange)
      } compactTrailing: {
        Text(context.state.estimatedDeliveryTime)
          .font(.caption)
      } minimal: {
        Image(systemName: "bag.fill")
          .foregroundColor(.orange)
      }
    }
  }

  private func statusIcon(for status: String) -> String {
    switch status {
    case "Preparing":
      return "flame.fill"
    case "On the way":
      return "car.fill"
    case "Delivered":
      return "checkmark.circle.fill"
    default:
      return "clock.fill"
    }
  }
}
