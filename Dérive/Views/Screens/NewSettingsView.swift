import SwiftUI
import SwiftData
import UIKit

// MARK: - Settings View

/// Settings screen with app preferences
/// Tab 3 in the app navigation
struct NewSettingsView: View {
    @Query(
        filter: #Predicate<SpotData> { spot in
            spot.list?.isDownloaded == true && spot.list?.notifyWhenNearby == true
        }
    ) private var activeSpots: [SpotData]

    @ObservedObject private var settingsService = SettingsService.shared
    @State private var showMapAppPicker = false

    var body: some View {
        NavigationStack {
            List {
                // Main Settings Section
                Section {
                    Button {
                        showMapAppPicker = true
                    } label: {
                        LabeledContent("Default Map App", value: mapAppDisplayName)
                    }
                    .foregroundStyle(Color.labelPrimary)

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
            .navigationDestination(isPresented: $showMapAppPicker) {
                MapAppPickerView()
            }
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
                Text("When set, tapping the notification opens your preferred map app with directions.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Map Apps")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Previews

#Preview("Settings") {
    NewSettingsView()
        .modelContainer(PreviewContainer.containerWithData)
}

#Preview("Map App Picker") {
    NavigationStack {
        MapAppPickerView()
    }
}
