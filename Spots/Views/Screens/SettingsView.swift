//
//  SettingsView.swift
//  Purpose: Settings screen with app preferences
//  Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-30.
//

import SwiftUI
import SwiftData

// MARK: - Settings View

/// Settings screen with app preferences
/// Tab 3 in the app navigation
struct SettingsView: View {
    @Query(
        filter: #Predicate<SpotData> { spot in
            spot.list?.isDownloaded == true && spot.list?.notifyWhenNearby == true
        }
    ) private var activeSpots: [SpotData]

    @Environment(\.openURL) private var openURL
    @ObservedObject private var settingsService = SettingsService.shared

    var body: some View {
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
                Text("This app monitors up to 20 nearest spots.")
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
        .standardListStyle()
        .contentMargins(.top, 16, for: .scrollContent)
        .largeNavigationTitle("Settings")
    }

    // MARK: - Helpers

    private var mapAppDisplayName: String {
        settingsService.defaultMapApp?.displayName ?? "Ask Next Time"
    }

    private func openIOSSettings() {
        openURL(.appSettings)
    }
}

// MARK: - Previews

#Preview("Settings") {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(PreviewContainer.containerWithData)
}
