//
//  Item.swift
//  ToDoApp
//
//  Created by Bhumi Thummar on 08/05/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
