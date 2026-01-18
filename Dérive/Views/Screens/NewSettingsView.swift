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
            VStack(spacing: 0) {
                LargeTitleHeader(title: "Settings")

                ScrollView {
                    VStack(spacing: Spacing.medium) {
                        mainSettingsSection
                        iosSettingsSection
                    }
                    .padding(.top, Spacing.small)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.backgroundGroupedPrimary)
            .navigationDestination(isPresented: $showMapAppPicker) {
                MapAppPickerView(onBack: { showMapAppPicker = false })
            }
        }
    }

    // MARK: - Main Settings Section

    private var mainSettingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            GroupedCard {
                VStack(spacing: 0) {
                    DrillRow(
                        title: "Default Map App",
                        value: mapAppDisplayName
                    ) {
                        showMapAppPicker = true
                    }

                    RowSeparator()

                    InfoRow(label: "Active geofences", value: "\(min(activeSpots.count, 20))")
                }
            }
            .padding(.horizontal, Spacing.medium)

            SectionFooter(text: "Dérive monitors up to 20 nearest spots from your downloaded lists.")
        }
    }

    // MARK: - iOS Settings Section

    private var iosSettingsSection: some View {
        GroupedCard {
            LinkRow(label: "iOS App Settings") {
                openIOSSettings()
            }
        }
        .padding(.horizontal, Spacing.medium)
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
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            NavigationHeader(title: "Default Map App", onBack: onBack)

            ScrollView {
                VStack(spacing: 0) {
                    optionsSection
                }
                .padding(.top, Spacing.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.backgroundGroupedPrimary)
        .navigationBarHidden(true)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            GroupedCard {
                VStack(spacing: 0) {
                    SelectableRow(
                        title: "Ask Next Time",
                        isSelected: settingsService.defaultMapApp == nil
                    ) {
                        settingsService.defaultMapApp = nil
                    }

                    RowSeparator()

                    SelectableRow(
                        title: "Apple Maps",
                        isSelected: settingsService.defaultMapApp == .appleMaps
                    ) {
                        settingsService.defaultMapApp = .appleMaps
                    }

                    RowSeparator()

                    SelectableRow(
                        title: "Google Maps",
                        isSelected: settingsService.defaultMapApp == .googleMaps
                    ) {
                        settingsService.defaultMapApp = .googleMaps
                    }
                }
            }
            .padding(.horizontal, Spacing.medium)

            SectionFooter(text: "When set, tapping the notification opens your preferred map app with directions.")
        }
    }
}

// MARK: - Previews

#Preview("Settings") {
    NewSettingsView()
        .modelContainer(PreviewContainer.containerWithData)
}

#Preview("Map App Picker") {
    MapAppPickerView(onBack: {})
}
