//
//  SettingsView.swift
//  Purpose: Settings screen with app preferences
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-30.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Settings View

/// Settings screen with app preferences
/// Tab 3 in the app navigation
struct SettingsView: View {
    @Query(
        filter: #Predicate<SpotData> { spot in
            spot.list?.isDownloaded == true && spot.list?.notifyWhenNearby == true
        }
    ) private var activeSpots: [SpotData]

    @ObservedObject private var settingsService = SettingsService.shared

    var body: some View {
        NavigationStack {
            List {
                // Main Settings Section
                Section {
                    NavigationLink {
                        MapAppPickerView()
                    } label: {
                        LabeledContent("Default Map App", value: mapAppDisplayName)
                    }

                    LabeledContent("Active geofences", value: "\(min(activeSpots.count, 20))")
                } footer: {
                    Text("Dérive monitors up to 20 nearest spots from your downloaded lists.")
                }

                // iOS Settings Section
                Section {
                    Button {
                        openIOSSettings()
                    } label: {
                        Text("iOS App Settings")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Helpers

    private var mapAppDisplayName: String {
        settingsService.defaultMapApp?.displayName ?? "Ask Next Time"
    }

    private func openIOSSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Map App Picker View

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
                            .foregroundStyle(Color.labelPrimary)
                        Spacer()
                        if settingsService.defaultMapApp == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentBlue)
                        }
                    }
                }

                Button {
                    settingsService.defaultMapApp = .appleMaps
                } label: {
                    HStack {
                        Text("Apple Maps")
                            .foregroundStyle(Color.labelPrimary)
                        Spacer()
                        if settingsService.defaultMapApp == .appleMaps {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentBlue)
                        }
                    }
                }

                Button {
                    settingsService.defaultMapApp = .googleMaps
                } label: {
                    HStack {
                        Text("Google Maps")
                            .foregroundStyle(Color.labelPrimary)
                        Spacer()
                        if settingsService.defaultMapApp == .googleMaps {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentBlue)
                        }
                    }
                }
            } footer: {
                Text("This will set your preferred map app when you select the Get Direction button")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Map Apps")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Previews

#Preview("Settings") {
    SettingsView()
        .modelContainer(PreviewContainer.containerWithData)
}

#Preview("Map App Picker") {
    NavigationStack {
        MapAppPickerView()
    }
}
