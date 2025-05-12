//
//  AddToDoView.swift
//  ToDoApp
//
//  Created by Bhumi Thummar on 07/05/25.
//

import SwiftUI
import SwiftData

struct AddToDoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var dueDate: Date
    @State private var selectPriority : Priority =  Priority.normal

    var todoItem: ToDoItem?

    init(todoItem: ToDoItem? = nil) {
        self.todoItem = todoItem
        _title = State(initialValue: todoItem?.title ?? "")
        _dueDate = State(initialValue: todoItem?.dueDate ?? Date())
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("To-Do Details")) {
                    TextField("Title", text: $title)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    HStack{
                        Text("Select Priority")
                        Spacer()
                        Menu {
                            ForEach(Priority.allCases,id:\.rawValue) { priority in
                                Button(action: {
                                    selectPriority = priority
                                }, label: {
                                    HStack {
                                        Text(priority.rawValue)
                                        if selectPriority  == priority { Image (systemName: "checkmark")
                                        }
                                    }
                                })
                            }
                        }label: {
                            Image(systemName: "circle.fill")
                                .font(.title2)
                                .padding (3)
                                .contentShape(.rect)
                                .foregroundStyle(selectPriority.color.gradient)
                        }
                    }
                }
            }
            .navigationTitle(todoItem == nil ? "Add" : "Edit")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button(todoItem == nil ? "Add To-Do" : "Save Changes") {
                    addOrEditToDo()
                }
            )
        }
    }

    private func addOrEditToDo() {
        guard !title.isEmpty else {
            AlertGlobal.showOkAlert(message: "Please enter title")
            return
        }

        if let item = todoItem {
            // Editing
            item.title = title
            item.dueDate = dueDate
        } else {
            // Adding
            let newItem = ToDoItem(title: title, dueDate: dueDate, priority: selectPriority)
            modelContext.insert(newItem)
        }

        do {
            try modelContext.save()

//            // Update widgets if needed
//            let todayItems = ToDoService.shared.fetchToDos(for: .today, context: modelContext)
//            let tomorrowItems = ToDoService.shared.fetchToDos(for: .tomorrow, context: modelContext)
//            WidgetDataManager.shared.saveToDos(today: todayItems, tomorrow: tomorrowItems)

            dismiss()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved SwiftData error \(nsError), \(nsError.userInfo)")
        }
    }
}





#Preview {
    AddToDoView()
}
