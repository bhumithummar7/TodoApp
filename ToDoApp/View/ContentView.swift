//
//  ContentView.swift
//  ToDoApp
//
//  Created by Bhumi Thummar on 07/05/25.
//

import SwiftUI
import SwiftData
import WidgetKit
enum ToDoFilter: String, CaseIterable, Identifiable {
    case today = "Today"
    case upcoming = "Upcoming"
    case past = "Past"
    case all = "All"

    var id: String { self.rawValue }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\ToDoItem.dueDate, order: .forward)]) var items: [ToDoItem] = []

    @State private var showingAddView = false
    @State private var selectedToDoItem: ToDoItem?
    @Environment(\.scenePhase) var scenePhase
    @State private var refreshID = UUID()
    @State private var selectedFilter: ToDoFilter = .today
    @State private var showingSettings = false

    var filteredItems: [ToDoItem] {
        let now = Calendar.current.startOfDay(for: Date())
        return items.filter { item in
            let due = Calendar.current.startOfDay(for: item.dueDate)
            switch selectedFilter {
                case .today:
                    return Calendar.current.isDateInToday(due)
                case .upcoming:
                    return due > now
                case .past:
                    return due < now && !Calendar.current.isDateInToday(due)
                case .all:
                    return true
            }
        }
        .sorted { $0.dueDate > $1.dueDate }
    }
    func generateDailyTodos(context: ModelContext) {
        let request = FetchDescriptor<ToDoItem>()
        if let items = try? context.fetch(request) {
            for item in items {
                guard (item.repeatOption != RepeatOption.none && item.isMaster) else { continue }

                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())

                // Skip if end date passed
//                if let end = item.repeatEndDate, today > end { continue }

                if item.repeatEndOption == .onDate,
                   let endDate = item.repeatEndDate,
                   today > Calendar.current.startOfDay(for: endDate) {
                    continue
                }
                
                // If today already exists → skip
                if items.contains(where: { $0.title == item.title && calendar.isDate($0.dueDate, inSameDayAs: today) }) {
                    continue
                }

                // Check if today matches repeat rule
                var shouldCreate = false
                switch item.repeatOption {
                case .daily:
                    shouldCreate = true
                case .weekly:
                    let weekday = calendar.component(.weekday, from: today)
                    shouldCreate = (weekday == item.repeatDayOfWeek)
                case .monthly:
                    let day = calendar.component(.day, from: today)
                    shouldCreate = (day == item.repeatDayOfMonth)
                default:
                    break
                }

                if shouldCreate {
                    let newItem = ToDoItem(title: item.title,
                                           dueDate: today,
                                           priority: item.priority,
                                           repeatOption: item.repeatOption,
                                           repeatDayOfWeek:item.repeatDayOfWeek,
                                           repeatDayOfMonth:item.repeatDayOfMonth,
                                           repeatEndOption:item.repeatEndOption,
                                           repeatEndDate:item.repeatEndDate,
                                           isMaster:false,
                                           parentID: item.taskID) // Occurrences don’t repeat
                    context.insert(newItem)
                }
            }

            try? context.save()
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ToDoFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                if groupedToDosByDay(filteredItems).count > 0 {
                    List {
                        ForEach(groupedToDosByDay(filteredItems), id: \.0) { (section, todos) in
                            Section(header: Text(section)) {
                                ForEach(todos.sorted(by: { $0.dueDate > $1.dueDate }), id: \.self) { item in
                                    ToDoCardView(item: item)
                                        .swipeActions {
                                            Button {
                                                AlertGlobal.showAlertWithActionWithCancel(
                                                    title: "",
                                                    message: "Are you sure you want to delete this To-do?",
                                                    style: .alert,
                                                    actionTitles: [],
                                                    showCancel: true,
                                                    deleteTitle: "Delete"
                                                ) { _ in
                                                    deleteToDoItem(item)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            .tint(.red)

                                            Button {
//                                                selectedToDoItem = item
//                                                showingAddView.toggle()
                                                selectedToDoItem = item
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.orange)
                                        }
                                }
                            }
                        }
                    }
                    .id(refreshID)
                    .listStyle(.insetGrouped)
                } else {
                    Spacer()
                    Text("No To-Do Items")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                    Spacer()
                }
            }
            .navigationTitle("To-Do List")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                            .foregroundColor(Color.black)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        AlertGlobal.showAlertWithActionWithCancel(
                            title: "",
                            message: "Are you sure you want to delete all To-do?",
                            style: .alert,
                            actionTitles: [],
                            showCancel: true,
                            deleteTitle: "Delete"
                        ) { _ in
                            self.deleteAll(of: ToDoItem.self)
                        }
                    }) {
                        Image(systemName: "trash.fill").foregroundColor(Color.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        selectedToDoItem = nil
                        showingAddView.toggle()
                    }) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddToDoView(todoItem: selectedToDoItem)
                    .environment(\.modelContext, modelContext)
            }
            .sheet(item: $selectedToDoItem) { todo in
                AddToDoView(todoItem: todo)
                    .environment(\.modelContext, modelContext)
            }
            .fullScreenCover(isPresented: $showingSettings) {
                SettingsView()
            }
            .onChange(of: scenePhase) {
                switch scenePhase {
                    case .active:
                        self.generateDailyTodos(context: modelContext)
                        refreshID = UUID()
                    case .background:
                        WidgetCenter.shared.reloadAllTimelines()
                    default:
                        break
                }
            }
        }
    }

    private func groupedToDosByDay(_ todos: [ToDoItem]) -> [(String, [ToDoItem])] {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeZone = TimeZone.current

        let grouped = Dictionary(grouping: todos) { todo -> String in
            let date = calendar.startOfDay(for: todo.dueDate)
            
            switch selectedFilter {
            case .today:
                return "Today"
            case .upcoming:
                if calendar.isDateInTomorrow(date) {
                    return "Tomorrow"
                } else {
                    return formatter.string(from: date)
                }
            case .past, .all:
                if calendar.isDateInToday(date) {
                    return "Today"
                } else if calendar.isDateInTomorrow(date) {
                    return "Tomorrow"
                } else {
                    return formatter.string(from: date)
                }
            }
        }

        return grouped
            // sort todos inside each section: latest first
            .mapValues { $0.sorted { $0.dueDate > $1.dueDate } }
            // sort sections: latest date first
            .sorted { a, b in
                let d1 = a.value.first?.dueDate ?? .distantPast
                let d2 = b.value.first?.dueDate ?? .distantPast
                return d1 > d2
            }
    }



    private func deleteToDoItem(_ item: ToDoItem) {
        withAnimation {
            modelContext.delete(item)
        }
    }

    private func deleteAll<T: PersistentModel>(of type: T.Type) {
        let descriptor = FetchDescriptor<T>()
        if let results = try? modelContext.fetch(descriptor) {
            for item in results {
                modelContext.delete(item)
            }
        }
        try? modelContext.save()
    }
}

#Preview {
    ContentView()
}
