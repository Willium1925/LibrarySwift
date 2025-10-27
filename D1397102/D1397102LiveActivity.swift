//
//  D1397102LiveActivity.swift
//  D1397102
//
//  Created by fcuiecs on 2025/10/27.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct D1397102Attributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct D1397102LiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: D1397102Attributes.self) { context in
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

extension D1397102Attributes {
    fileprivate static var preview: D1397102Attributes {
        D1397102Attributes(name: "World")
    }
}

extension D1397102Attributes.ContentState {
    fileprivate static var smiley: D1397102Attributes.ContentState {
        D1397102Attributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: D1397102Attributes.ContentState {
         D1397102Attributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: D1397102Attributes.preview) {
   D1397102LiveActivity()
} contentStates: {
    D1397102Attributes.ContentState.smiley
    D1397102Attributes.ContentState.starEyes
}
