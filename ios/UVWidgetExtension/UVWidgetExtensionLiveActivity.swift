//
//  UVWidgetExtensionLiveActivity.swift
//  UVWidgetExtension
//
//  Created by Aryamann Chaudhary on 19/03/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct UVWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct UVWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: UVWidgetExtensionAttributes.self) { context in
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

extension UVWidgetExtensionAttributes {
    fileprivate static var preview: UVWidgetExtensionAttributes {
        UVWidgetExtensionAttributes(name: "World")
    }
}

extension UVWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: UVWidgetExtensionAttributes.ContentState {
        UVWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: UVWidgetExtensionAttributes.ContentState {
         UVWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: UVWidgetExtensionAttributes.preview) {
   UVWidgetExtensionLiveActivity()
} contentStates: {
    UVWidgetExtensionAttributes.ContentState.smiley
    UVWidgetExtensionAttributes.ContentState.starEyes
}
