//
//  DeliveryLiveActivityWidgetLiveActivity.swift
//  DeliveryLiveActivityWidget
//
//  Created by Hyeonji Shin on 1/13/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DeliveryLiveActivityWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct DeliveryLiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DeliveryLiveActivityWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension DeliveryLiveActivityWidgetAttributes {
    fileprivate static var preview: DeliveryLiveActivityWidgetAttributes {
        DeliveryLiveActivityWidgetAttributes(name: "World")
    }
}

extension DeliveryLiveActivityWidgetAttributes.ContentState {
    fileprivate static var smiley: DeliveryLiveActivityWidgetAttributes.ContentState {
        DeliveryLiveActivityWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: DeliveryLiveActivityWidgetAttributes.ContentState {
         DeliveryLiveActivityWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: DeliveryLiveActivityWidgetAttributes.preview) {
   DeliveryLiveActivityWidgetLiveActivity()
} contentStates: {
    DeliveryLiveActivityWidgetAttributes.ContentState.smiley
    DeliveryLiveActivityWidgetAttributes.ContentState.starEyes
}
