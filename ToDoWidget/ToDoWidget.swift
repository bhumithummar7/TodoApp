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

    @Query(Self.todoDescriptor, animation: .snappy) private var todosForDate: [ToDoItem]

    private var filteredItems: [ToDoItem] {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        var filtered: [ToDoItem] = []

        for todo in todosForDate {
            let dueDate = calendar.startOfDay(for: todo.dueDate)
            if entry.date == now {
                filtered.append(todo)
            } else if dueDate > now {
                filtered.append(todo)
            } else {
                filtered.append(todo)
            }
        }
        return filtered.sorted { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        ZStack {
            
            if let settings = loadWidgetSettings() {
                if settings.backgroundType == .none {
                    Color.black.ignoresSafeArea().zIndex(-1)
                }
                else if settings.backgroundType == .gradient {
                    if settings.gradientMode == .selectOne, let idx = settings.selectedGradientIndex {
                        // Use gradients[idx]
                        WidgetSettingsManager.shared.gradients[idx]
                    } else {
                        entry.date.backgroundGradient
                            .ignoresSafeArea()
                            .zIndex(-1)
                    }
                } else if settings.backgroundType == .photo, let photoData = settings.selectedPhotoData,photoData.count > 0 {
                    let weekday = Calendar.current.component(.weekday, from: entry.date)
                    if let uiImage = UIImage(data: photoData[photoData.count == 7 ? (weekday - 1) % 7 :  abs(Int(entry.date.timeIntervalSince1970 / 86400)) % photoData.count]) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                        
                        // Dark overlay to improve text visibility
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.black.opacity(0.8),
                                        Color.black.opacity(0.6)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .ignoresSafeArea()
                    }
                }
                else{
                    entry.date.backgroundGradient
                        .ignoresSafeArea()
                        .zIndex(-1)
                }
            }
            

            VStack(alignment: .leading, spacing: 0) {
                Text("Hii").frame(height: 12).foregroundColor(Color.clear)
                HStack {
                    Text(" 📋 Today's Tasks")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                Divider()
                    .background(Color.white.opacity(0.25))
                    .frame(height: 1)
                    .padding(.top, 4)
                    .padding(.bottom, -5)
                if filteredItems.isEmpty {
                    VStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                        Text("No Tasks Today!")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: -6) {
                        ForEach(filteredItems.prefix(5)) { todo in
                            HStack(spacing: 8) {
                                Button(intent: ToggleButton(id: todo.taskID)) {
                                    Image(systemName: todo.isCompleted ? "checkmark" : "square")
                                        .foregroundColor(todo.isCompleted ? .green : .gray)
                                        .font(.system(size: 16,weight: .bold))
                                }
                                .buttonStyle(.plain)
                                .frame(width: 24, height: 24)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(todo.title)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Circle()
                                    .fill(todo.priority.color)
                                    .frame(width: 7, height: 7)
                            }
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.clear)
                            )
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
        }
    }

    static var todoDescriptor: FetchDescriptor<ToDoItem> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = #Predicate<ToDoItem> {
            $0.dueDate >= startOfDay && $0.dueDate < endOfDay
        }
        let sort = [SortDescriptor(\ToDoItem.dueDate, order: .forward)]
        return FetchDescriptor(predicate: predicate, sortBy: sort)
    }
    
    
    func loadWidgetSettings() -> WidgetSettings? {
        WidgetSettingsManager.shared.load()
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
            .disableContentMarginsIfNeeded()
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

extension WidgetConfiguration {
    func disableContentMarginsIfNeeded() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
    }
}
extension Date {
    var backgroundGradient: LinearGradient {
        let weekday = Calendar.current.component(.weekday, from: self)

        switch weekday {
        case 1: // Sunday
                return LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.25), Color.pink.opacity(0.2)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        case 2:
            return LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.3), Color.gray.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 3:
            return LinearGradient(
                gradient: Gradient(colors: [Color.indigo.opacity(0.25), Color.teal.opacity(0.15)]),
                startPoint: .top,
                endPoint: .bottom
            )
        case 4:
            return  LinearGradient(
                gradient: Gradient(colors: [Color.mint.opacity(0.3), Color.cyan.opacity(0.2)]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        case 5:
                return LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
        case 6:
            return LinearGradient(
                gradient: Gradient(colors: [Color(hue: 0.72, saturation: 0.6, brightness: 0.4).opacity(0.4), Color(hue: 0.6, saturation: 0.2, brightness: 0.3).opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(
                gradient: Gradient(colors: [Color(hue: 0.38, saturation: 0.6, brightness: 0.3).opacity(0.4), Color(hue: 0.65, saturation: 0.5, brightness: 0.25).opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

}
