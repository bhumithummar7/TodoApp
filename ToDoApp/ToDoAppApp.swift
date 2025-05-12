//
//  ToDoAppApp.swift
//  ToDoApp
//
//  Created by Bhumi Thummar on 08/05/25.
//

import SwiftUI
import SwiftData

@main
struct ToDoAppApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ToDoItem.self)
    }
}
