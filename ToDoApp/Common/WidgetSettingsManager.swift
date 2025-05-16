//
//  WidgetSettingsManager.swift
//  ToDoApp
//
//  Created by Bhumi Thummar on 16/05/25.
//

import Foundation
import SwiftUI

enum WidgetBackgroundType: String, Codable {
    case none, gradient, photo
}

enum GradientMode: String, Codable {
    case selectOne, randomWeekly
}

struct WidgetSettings: Codable {
    var backgroundType: WidgetBackgroundType = .gradient
    var gradientMode: GradientMode = .randomWeekly
    var selectedGradientIndex: Int?
    var selectedPhotoData: [Data]? // Store images as Data
}

class WidgetSettingsManager {
    static let shared = WidgetSettingsManager()
    let suiteName = "group.com.app.ToDoApp" // <-- Use your real app group ID
    let key = "widgetSettings"

    let gradients: [LinearGradient] = [
        LinearGradient(
        gradient: Gradient(colors: [Color.orange.opacity(0.25), Color.pink.opacity(0.2)]),
        startPoint: .leading,
        endPoint: .trailing
    ),
        LinearGradient(
            gradient: Gradient(colors: [Color.black.opacity(0.3), Color.gray.opacity(0.2)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        LinearGradient(
            gradient: Gradient(colors: [Color.indigo.opacity(0.25), Color.teal.opacity(0.15)]),
            startPoint: .top,
            endPoint: .bottom
        ),
        LinearGradient(
            gradient: Gradient(colors: [Color.mint.opacity(0.3), Color.cyan.opacity(0.2)]),
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        ),
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        LinearGradient(
            gradient: Gradient(colors: [Color(hue: 0.72, saturation: 0.6, brightness: 0.4).opacity(0.4), Color(hue: 0.6, saturation: 0.2, brightness: 0.3).opacity(0.3)]),
            startPoint: .top,
            endPoint: .bottom
        ),
        LinearGradient(
            gradient: Gradient(colors: [Color(hue: 0.38, saturation: 0.6, brightness: 0.3).opacity(0.4), Color(hue: 0.65, saturation: 0.5, brightness: 0.25).opacity(0.3)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    ]
    
    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    func save(_ settings: WidgetSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults?.set(data, forKey: key)
        }
    }
    
    func load() -> WidgetSettings {
        guard let data = defaults?.data(forKey: key),
              let settings = try? JSONDecoder().decode(WidgetSettings.self, from: data) else {
            // Return default settings if nothing is saved or decoding fails
            return WidgetSettings(
                backgroundType: .gradient,
                gradientMode: .randomWeekly,
                selectedGradientIndex: nil,
                selectedPhotoData: nil
            )
        }
        return settings
    }
}
