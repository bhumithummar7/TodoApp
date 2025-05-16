//
//  SettingsView.swift
//  ToDoApp
//
//  Created by Bhumi Thummar on 16/05/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showEditWidget = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Widget")) {
                    NavigationLink(destination: EditWidgetView()) {
                        Text("Edit Widget")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
