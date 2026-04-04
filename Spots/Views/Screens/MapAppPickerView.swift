//
//  MapAppPickerView.swift
//  Purpose: Picker screen for selecting the default map app
//  Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2026-04-03.
//

import SwiftUI

struct MapAppPickerView: View {
    @ObservedObject private var settingsService = SettingsService.shared

    var body: some View {
        List {
            Section {
                SelectableRow("Ask Next Time", isSelected: settingsService.defaultMapApp == nil) {
                    settingsService.defaultMapApp = nil
                }
                SelectableRow("Apple Maps", isSelected: settingsService.defaultMapApp == .appleMaps) {
                    settingsService.defaultMapApp = .appleMaps
                }
                SelectableRow("Google Maps", isSelected: settingsService.defaultMapApp == .googleMaps) {
                    settingsService.defaultMapApp = .googleMaps
                }
            } footer: {
                Text("This will set your preferred map app when you select the \"Get direction\" button")
            }
        }
        .standardListStyle()
        .contentMargins(.top, 16, for: .scrollContent)
        .largeNavigationTitle("Map Apps")
    }
}

// MARK: - Selectable Row

private struct SelectableRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    init(_ label: String, isSelected: Bool, action: @escaping () -> Void) {
        self.label = label
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label).foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Map App Picker") {
    NavigationStack {
        MapAppPickerView()
    }
}
