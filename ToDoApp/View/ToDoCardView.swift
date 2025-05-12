//
//  ToDoCardView.swift
//  ToDoApp
//
//  Created by Bhumi Thummar on 07/05/25.
//
import SwiftUI
import SwiftData

struct ToDoCardView: View {
    @Bindable var item: ToDoItem
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(alignment: .center) {
            Button(action: {
                item.isCompleted.toggle()
                saveItem()
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .gray)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.headline)
                    .strikethrough(item.isCompleted, color: .gray)
                    .foregroundColor(item.isCompleted ? .gray : .primary)
            }

            Spacer()
            HStack{
                Text(item.dueDate, style: .time)
                    .font(.caption)
                    .foregroundColor(.gray)
                Menu {
                    ForEach(Priority.allCases,id:\.rawValue) { priority in
                        Button(action: {
                            item.priority = priority
                            saveItem()
                        }, label: {
                            HStack {
                                Text(priority.rawValue)
                                if item.priority  == priority { Image (systemName: "checkmark")
                                }
                            }
                        })
                    }
                }label: {
                    Image(systemName: "circle.fill")
                        .font(.title2)
                        .padding (3)
                        .contentShape(.rect)
                        .foregroundStyle (item.priority.color.gradient)
                }
            }
        }
        .padding(.vertical, 5)
    }

    private func saveItem() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save item: \(error.localizedDescription)")
        }
    }
}



//#Preview {
//    ToDoCardView()
//}
