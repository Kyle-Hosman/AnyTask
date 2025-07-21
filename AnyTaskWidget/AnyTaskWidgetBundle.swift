//
//  AnyTaskWidgetBundle.swift
//  AnyTaskWidget
//
//  Created by Kyle Hosman on 7/21/25.
//

import WidgetKit
import SwiftUI

@main
struct AnyTaskWidgetBundle: WidgetBundle {
    var body: some Widget {
        AnyTaskWidget()
        AnyTaskWidgetControl()
        AnyTaskWidgetLiveActivity()
    }
}
