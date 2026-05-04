//
//  GardenWidgetBundle.swift
//  GardenWidget
//

import WidgetKit
import SwiftUI

@main
struct GardenWidgetBundle: WidgetBundle {
    var body: some Widget {
        GardenInboxWidget()
        GardenCalmWidget()
        GardenLockWidget()
    }
}
