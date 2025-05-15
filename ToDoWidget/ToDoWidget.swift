//
//  ToDoWidget.swift
//  ToDoWidget
//
//  Created by Bhumi Thummar on 08/05/25.

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - Timeline Provider
struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        
        // Add an entry with today's date to refresh the widget
        entries.append(SimpleEntry(date: Date()))
        
        return Timeline(entries: entries, policy: .atEnd)
    }
}

// MARK: - Timeline Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
}

// MARK: - Widget View
struct ToDoWidgetEntryView: View {
    var entry: Provider.Entry
    
    /// Query that fetches all todos based on a specific date (defaults to today if no date passed)
    @Query(Self.todoDescriptor, animation: .snappy) private var todosForDate: [ToDoItem]
    
    // Filter today's, tomorrow's, and past todos
    private var filteredItems: [ToDoItem] {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        var filtered: [ToDoItem] = []
        
        for todo in todosForDate {
            let dueDate = calendar.startOfDay(for: todo.dueDate)
            
            if entry.date == now { // Today
                filtered.append(todo)
            } else if dueDate > now { // Future
                filtered.append(todo)
            } else { // Past
                filtered.append(todo)
            }
        }
        
        return filtered.sorted { ($0.dueDate) > ($1.dueDate) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if filteredItems.isEmpty {
                Text("No Tasks Today 🎉")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing:2){
                    HStack{
                        Text("Today's Task")
                            .font(.system(size: 12,weight: .semibold))
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    ForEach(filteredItems.prefix(4)) { todo in // Show top 5 (can be adjusted)
                        VStack(spacing:0){
                            HStack(spacing: 8) {
                                Button(intent: ToggleButton(id: todo.taskID)) {
                                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(todo.isCompleted ? .green : Color.kBlack)
                                }
                                .frame(width: 30,height: 30)
                                .tint(.clear)//tint(todo.isCompleted ? .green : .gray)
                                .buttonBorderShape (.circle)
                                .font(.callout)
                                Text(todo.title)
                                    .foregroundColor(todo.priority.color)
                                    .font(.system(size: 12,weight: .medium))
                                    .lineLimit(1)
                                Spacer()
                            }.padding(.horizontal)
                        }
                        .background(todo.priority.color.opacity(0.1))
                        .cornerRadius(5)
                        .padding(.bottom,2)
                    }
                }
            }
        }
    }

    static var todoDescriptor: FetchDescriptor<ToDoItem> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // You can adjust the predicate to match the passed date if you want to make the date dynamic
        let predicate = #Predicate<ToDoItem> {
            $0.dueDate >= startOfDay && $0.dueDate < endOfDay
        }
        
        let sort = [SortDescriptor(\ToDoItem.dueDate, order: .forward)]
        return FetchDescriptor(predicate: predicate, sortBy: sort)
    }

}


// MARK: - Main Widget
struct ToDoWidget: Widget {
    let kind: String = "ToDoWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            ToDoWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .modelContainer(for: ToDoItem.self)
        }.supportedFamilies([.systemMedium])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    ToDoWidget()
} timeline: {
    SimpleEntry(date: .now)
}

// MARK: - Toggle Button Intent
struct ToggleButton: AppIntent {
    static var title: LocalizedStringResource = "Toggle Todo Completion"

    @Parameter(title: "Todo ID")
    var id: String

    init() {}
    
    init(id: String) {
        self.id = id
    }

    func perform() async throws -> some IntentResult {
        let context = try ModelContext(.init(for: ToDoItem.self))
        
        let descriptor = FetchDescriptor(predicate: #Predicate<ToDoItem> { $0.taskID == id })
        
        if let todo = try context.fetch(descriptor).first {
            todo.isCompleted.toggle()
            try context.save()
        }
        return .result()
    }
}

