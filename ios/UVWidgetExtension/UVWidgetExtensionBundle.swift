//
//  UVWidgetExtensionBundle.swift
//  UVWidgetExtension
//
//  Created by Aryamann Chaudhary on 19/03/26.
//

import WidgetKit
import SwiftUI

@main
struct UVWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        UVWidget()
        // UVWidgetExtensionControl() // Requires iOS 18.0+
        // UVWidgetExtensionLiveActivity() // Requires iOS 16.1+
    }
}
