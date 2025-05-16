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
                                                selectedToDoItem = item
                                                showingAddView.toggle()
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
                        showingAddView.toggle()
                        selectedToDoItem = nil
                    }) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddToDoView(todoItem: selectedToDoItem)
                    .environment(\.modelContext, modelContext)
            }
            .fullScreenCover(isPresented: $showingSettings) {
                SettingsView()
            }
            .onChange(of: scenePhase) {
                switch scenePhase {
                    case .active:
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
            .mapValues { $0.sorted { $0.dueDate > $1.dueDate } }
            .sorted { a, b in
                let d1 = a.value.first?.dueDate ?? .distantFuture
                let d2 = b.value.first?.dueDate ?? .distantFuture
                return d1 < d2
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

/*struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\ToDoItem.dueDate, order: .forward)]) var items: [ToDoItem] = []

    @State private var showingAddView = false
    @State private var showAll = false
    @State private var selectedToDoItem: ToDoItem?
    @Environment(\.scenePhase) var scenePhase
    @State private var refreshID = UUID()

    var filteredItems: [ToDoItem]
    {
        let filtered = showAll
            ? items
            : items.filter {
                let due = $0.dueDate
                let startOfToday = Calendar.current.startOfDay(for: Date())
                return due >= startOfToday
            }

        return filtered.sorted { ($0.dueDate) > ($1.dueDate) }
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("Filter", selection: $showAll) {
                    Text("Upcoming").tag(false)
                    Text("All").tag(true)
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
                                                selectedToDoItem = item
                                                showingAddView.toggle()
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.orange)
                                        }
                                }
                            }
                        }
                    }.id(refreshID)
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
                        showingAddView.toggle()
                        selectedToDoItem = nil
                    }) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddToDoView(todoItem: selectedToDoItem)
                    .environment(\.modelContext, modelContext)
            }
            .onChange(of: scenePhase) {
                // intercept changes in application state to synchronise the data displayed to the user
                switch scenePhase {
                    case .active:
                        refreshID = UUID()
                        break
//                        self.fetchToDos()
                    // always reread all tasks from store when app goes from background to foreground to sync changes made in widget
                    //rereadUserTasks()
                case .background:
                    // update widget timeline to sync changes while app goes to background
                    WidgetCenter.shared.reloadAllTimelines()
                default:
                    break
                }

            }
        }
    }

    private func groupedToDosByDay(_ todos: [ToDoItem]) -> [(String, [ToDoItem])] {
        var future: [ToDoItem] = []
        var today: [ToDoItem] = []
        var past: [ToDoItem] = []

        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())

        for todo in todos {
            let due = todo.dueDate
            let dueDay = calendar.startOfDay(for: due)

            if calendar.isDateInToday(dueDay) {
                today.append(todo)
            } else if dueDay > now {
                future.append(todo)
            } else {
                past.append(todo)
            }
        }

        var sections: [(String, [ToDoItem])] = []

        if !future.isEmpty {
            let groupedFuture = Dictionary(grouping: future) { todo -> String in
                let date = calendar.startOfDay(for: todo.dueDate)
                if calendar.isDateInTomorrow(date) {
                    return "Tomorrow"
                } else {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .full
                    return formatter.string(from: date)
                }
            }

            let sortedFuture = groupedFuture
                .mapValues { $0.sorted { ($0.dueDate) > ($1.dueDate) } }
                .sorted { a, b in
                    let d1 = a.value.first?.dueDate ?? .distantFuture
                    let d2 = b.value.first?.dueDate ?? .distantFuture
                    return d1 < d2
                }

            sections.append(contentsOf: sortedFuture)
        }

        if !today.isEmpty {
            let sortedToday = today.sorted { ($0.dueDate) > ($1.dueDate) }
            sections.append(("Today", sortedToday))
        }

        if showAll && !past.isEmpty {
            let groupedPast = Dictionary(grouping: past) { todo -> String in
                let formatter = DateFormatter()
                formatter.dateStyle = .full
                return formatter.string(from: todo.dueDate)
            }

            let sortedPast = groupedPast
                .mapValues { $0.sorted { ($0.dueDate) > ($1.dueDate) } }
                .sorted { a, b in
                    let d1 = a.value.first?.dueDate ?? .distantPast
                    let d2 = b.value.first?.dueDate ?? .distantPast
                    return d1 > d2
                }

            sections.append(contentsOf: sortedPast)
        }

        return sections
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
}*/




#Preview {
    ContentView()
}
