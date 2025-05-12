//
//  ToDoWidgetBundle.swift
//  ToDoWidget
//
//  Created by Bhumi Thummar on 08/05/25.
//

import WidgetKit
import SwiftUI

@main
struct ToDoWidgetBundle: WidgetBundle {
    var body: some Widget {
        ToDoWidget()
        ToDoWidgetControl()
        ToDoWidgetLiveActivity()
    }
}
