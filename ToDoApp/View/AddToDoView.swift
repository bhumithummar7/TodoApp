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
    @State private var selectPriority: Priority = .normal
    @State private var repeatOption: RepeatOption = .none
    @State private var repeatEndOption: RepeatEndOption = .never
    @State private var repeatEndDate: Date? = nil

    var todoItem: ToDoItem?

    init(todoItem: ToDoItem? = nil) {
        self.todoItem = todoItem
        _title = State(initialValue: todoItem?.title ?? "")
        _dueDate = State(initialValue: todoItem?.dueDate ?? Date())
        _repeatOption = State(initialValue: todoItem?.repeatOption ?? .none)
        _repeatEndOption = State(initialValue: todoItem?.repeatEndOption ?? .never)
        _repeatEndDate = State(initialValue: todoItem?.repeatEndDate)
        
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
                        } label: {
                            Image(systemName: "circle.fill")
                                .font(.title2)
                                .padding(3)
                                .contentShape(.rect)
                                .foregroundStyle(selectPriority.color.gradient)
                        }
                    }
                    
                    Picker("Repeat Task", selection: $repeatOption) {
                        ForEach(RepeatOption.allCases, id: \.rawValue) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }

                    // WEEKLY → weekday picker
                    if repeatOption == .weekly {
                        Picker("Select Day of Week", selection: Binding(
                            get: { todoItem?.repeatDayOfWeek ?? Calendar.current.component(.weekday, from: dueDate) },
                            set: { newValue in
                                todoItem?.repeatDayOfWeek = newValue
                            })) {
                            ForEach(1...7, id: \.self) { day in
                                Text(Calendar.current.weekdaySymbols[day-1]).tag(day)
                            }
                        }
                    }

                    // MONTHLY → date picker
                    if repeatOption == .monthly {
                        DatePicker("Select Day of Month",
                                   selection: $dueDate,
                                   displayedComponents: .date)
                    }
                    // END REPEAT SECTION
                    if repeatOption != .none {
                        Section {
                            HStack {
                                Text("End Repeat")
                                Spacer()
                                Menu {
                                    Button("Never") {
                                        repeatEndOption = .never
                                        repeatEndDate = nil
                                    }
                                    Button("On Date") {
                                        repeatEndOption = .onDate
                                        repeatEndDate = repeatEndDate ?? Date()
                                    }
                                } label: {
                                    if repeatEndOption == .never {
                                        Text("Never").foregroundColor(.gray)
                                    } else if let endDate = repeatEndDate {
                                        Text("On \(endDate.formatted(date: .abbreviated, time: .omitted))")
                                            .foregroundColor(.gray)
                                    } else {
                                        Text("On Date").foregroundColor(.gray)
                                    }
                                }
                            }

                            if repeatEndOption == .onDate {
                                DatePicker("Select End Date",
                                           selection: Binding(
                                               get: { repeatEndDate ?? Date() },
                                               set: { repeatEndDate = $0 }),
                                           displayedComponents: .date)
                            }
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
            item.priority = selectPriority
            item.repeatOption = repeatOption
            item.repeatEndOption = repeatEndOption
            item.repeatEndDate = (repeatEndOption == .onDate) ? repeatEndDate : nil

            if repeatOption == .weekly {
                item.repeatDayOfWeek = todoItem?.repeatDayOfWeek ?? Calendar.current.component(.weekday, from: dueDate)
                item.repeatDayOfMonth = nil
            } else if repeatOption == .monthly {
                item.repeatDayOfMonth = Calendar.current.component(.day, from: dueDate)
                item.repeatDayOfWeek = nil
            } else {
                item.repeatDayOfWeek = nil
                item.repeatDayOfMonth = nil
            }
            
            var masterItem: ToDoItem? = nil
            if !item.isMaster, let parentID = item.parentID {
                masterItem = try? modelContext.fetch(
                    FetchDescriptor<ToDoItem>(predicate: #Predicate { $0.taskID == parentID })
                ).first
            }
            // Also update master if it exists
            if let master = masterItem {
                master.title = item.title
                master.priority = item.priority
                master.repeatOption = item.repeatOption
                master.repeatEndOption = item.repeatEndOption
                master.repeatEndDate = item.repeatEndDate
                master.repeatDayOfWeek = item.repeatDayOfWeek
                master.repeatDayOfMonth = item.repeatDayOfMonth
            }
            
            
        } else {
            // Adding
            let newItem = ToDoItem(title: title, dueDate: dueDate, priority: selectPriority, repeatOption: repeatOption)
            newItem.repeatOption = repeatOption
            newItem.repeatEndOption = repeatEndOption
            newItem.repeatEndDate = (repeatEndOption == .onDate) ? repeatEndDate : nil

            if repeatOption == .weekly {
                newItem.repeatDayOfWeek = todoItem?.repeatDayOfWeek ??
                    Calendar.current.component(.weekday, from: dueDate)
                newItem.repeatDayOfMonth = nil
            } else if repeatOption == .monthly {
                newItem.repeatDayOfMonth = Calendar.current.component(.day, from: dueDate)
                newItem.repeatDayOfWeek = nil
            } else {
                newItem.repeatDayOfWeek = nil
                newItem.repeatDayOfMonth = nil
            }
            modelContext.insert(newItem)
        }

        do {
            try modelContext.save()
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






#Preview {
    AddToDoView()
}
