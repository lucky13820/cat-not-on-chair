//
//  CatNotOnChairWidgetExtensionBundle.swift
//  CatNotOnChairWidgetExtension
//
//  Created by Ryan Yao on 2025-05-07.
//

import WidgetKit
import SwiftUI

@main
struct CatNotOnChairWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        CatNotOnChairWidgetExtensionControl()
        PomodoroLiveActivity()
    }
}
