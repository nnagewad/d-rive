//
//  MapAppPickerView.swift
//  Purpose: Picker screen for selecting the default map app
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2026-04-03.
//

import SwiftUI

struct MapAppPickerView: View {
    @ObservedObject private var settingsService = SettingsService.shared

    var body: some View {
        List {
            Section {
                Button {
                    settingsService.defaultMapApp = nil
                } label: {
                    HStack {
                        Text("Ask Next Time")
                            .foregroundStyle(.primary)
                        Spacer()
                        if settingsService.defaultMapApp == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }

                Button {
                    settingsService.defaultMapApp = .appleMaps
                } label: {
                    HStack {
                        Text("Apple Maps")
                            .foregroundStyle(.primary)
                        Spacer()
                        if settingsService.defaultMapApp == .appleMaps {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }

                Button {
                    settingsService.defaultMapApp = .googleMaps
                } label: {
                    HStack {
                        Text("Google Maps")
                            .foregroundStyle(.primary)
                        Spacer()
                        if settingsService.defaultMapApp == .googleMaps {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            } footer: {
                Text("This will set your preferred map app when you select the \"Get direction\" button")
            }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.top, 16, for: .scrollContent)
        .navigationTitle("Map Apps")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Preview

#Preview("Map App Picker") {
    NavigationStack {
        MapAppPickerView()
    }
}
