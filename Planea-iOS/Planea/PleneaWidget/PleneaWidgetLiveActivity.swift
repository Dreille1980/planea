//
//  PleneaWidgetLiveActivity.swift
//  PleneaWidget
//
//  Created by Frederic Dreyer on 2025-11-06.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PleneaWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct PleneaWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PleneaWidgetAttributes.self) { context in
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

extension PleneaWidgetAttributes {
    fileprivate static var preview: PleneaWidgetAttributes {
        PleneaWidgetAttributes(name: "World")
    }
}

extension PleneaWidgetAttributes.ContentState {
    fileprivate static var smiley: PleneaWidgetAttributes.ContentState {
        PleneaWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: PleneaWidgetAttributes.ContentState {
         PleneaWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: PleneaWidgetAttributes.preview) {
   PleneaWidgetLiveActivity()
} contentStates: {
    PleneaWidgetAttributes.ContentState.smiley
    PleneaWidgetAttributes.ContentState.starEyes
}
