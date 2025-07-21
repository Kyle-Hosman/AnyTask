//
//  AnyTaskWidgetLiveActivity.swift
//  AnyTaskWidget
//
//  Created by Kyle Hosman on 7/21/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AnyTaskWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct AnyTaskWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AnyTaskWidgetAttributes.self) { context in
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

extension AnyTaskWidgetAttributes {
    fileprivate static var preview: AnyTaskWidgetAttributes {
        AnyTaskWidgetAttributes(name: "World")
    }
}

extension AnyTaskWidgetAttributes.ContentState {
    fileprivate static var smiley: AnyTaskWidgetAttributes.ContentState {
        AnyTaskWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: AnyTaskWidgetAttributes.ContentState {
         AnyTaskWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: AnyTaskWidgetAttributes.preview) {
   AnyTaskWidgetLiveActivity()
} contentStates: {
    AnyTaskWidgetAttributes.ContentState.smiley
    AnyTaskWidgetAttributes.ContentState.starEyes
}
