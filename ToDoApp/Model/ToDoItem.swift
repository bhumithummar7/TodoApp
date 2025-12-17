//
//  ToDoItemModel.swift
//  ToDoWidgetExtension
//
//  Created by Bhumi Thummar on 08/05/25.
//

import Foundation
import SwiftData
import SwiftUI
@Model
class ToDoItem {
    var taskID: String
    var title: String
    var isCompleted: Bool = false
    var dueDate: Date = Date.now
    var priority: Priority = Priority.normal
    var repeatOption: RepeatOption?
    var repeatDayOfWeek: Int?   // 1 = Sunday, 2 = Monday … 7 = Saturday
    var repeatDayOfMonth: Int?  // 1–31
    var repeatEndOption: RepeatEndOption?
    var repeatEndDate: Date?
    var isMaster: Bool
    var parentID: String?

    init(title: String, dueDate: Date?, isCompleted: Bool = false,priority: Priority,repeatOption: RepeatOption? = RepeatOption.none,
         repeatDayOfWeek: Int? = nil, repeatDayOfMonth: Int? = nil,repeatEndOption: RepeatEndOption? = nil,repeatEndDate: Date? = nil,isMaster: Bool? = true,parentID: String? = nil) {
        self.taskID = UUID().uuidString
        self.title = title
        self.dueDate = dueDate ?? Date()
        self.isCompleted = isCompleted
        self.priority = priority
        self.repeatOption = repeatOption
        self.repeatDayOfWeek = repeatDayOfWeek
        self.repeatDayOfMonth = repeatDayOfMonth
        self.repeatEndOption = repeatEndOption
        self.repeatEndDate = repeatEndDate
        self.isMaster = isMaster ?? true
        self.parentID = parentID
    }
}
/// Priority Status
enum Priority: String, Codable, CaseIterable {
    case normal = "Normal"
    case medium = "Medium"
    case high = "High"
    /// Priority Color
    var color: Color {
        switch self {
            case .normal:
                return .green
            case .medium:
                return .yellow
            case .high:
                return .red
        }
    }
}

enum RepeatEndOption: String, Codable, CaseIterable {
    case never = "Never"
    case onDate = "On Date"
}
enum RepeatOption: String, Codable, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

extension ToDoItem {
    var completedSortValue: Int {
        return isCompleted ? 1 : 0
    }
}
