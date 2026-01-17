import SwiftUI

// MARK: - New Settings View

/// Settings screen with app preferences
/// Tab 3 in the app navigation
struct NewSettingsView: View {
    @State private var activeGeofences: Int
    @State private var showDefaultMapAppPicker: Bool = false

    var defaultMapApp: String
    var onDefaultMapAppTapped: (() -> Void)?
    var onOpenIOSSettings: (() -> Void)?

    init(
        activeGeofences: Int = 0,
        defaultMapApp: String = "Apple Maps",
        onDefaultMapAppTapped: (() -> Void)? = nil,
        onOpenIOSSettings: (() -> Void)? = nil
    ) {
        _activeGeofences = State(initialValue: activeGeofences)
        self.defaultMapApp = defaultMapApp
        self.onDefaultMapAppTapped = onDefaultMapAppTapped
        self.onOpenIOSSettings = onOpenIOSSettings
    }

    var body: some View {
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
    }

    // MARK: - Main Settings Section

    private var mainSettingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            GroupedCard {
                VStack(spacing: 0) {
                    DrillRow(
                        title: "Default Map App",
                        value: defaultMapApp
                    ) {
                        onDefaultMapAppTapped?()
                    }

                    RowSeparator()

                    InfoRow(label: "Active geofences", value: "\(activeGeofences)")
                }
            }
            .padding(.horizontal, Spacing.medium)

            SectionFooter(text: "Dérive can monitor up to 20 spots.")
        }
    }

    // MARK: - iOS Settings Section

    private var iosSettingsSection: some View {
        GroupedCard {
            LinkRow(label: "iOS App Settings") {
                onOpenIOSSettings?()
            }
        }
        .padding(.horizontal, Spacing.medium)
    }
}

// MARK: - Previews

#Preview("Settings") {
    NewSettingsView(
        activeGeofences: 5,
        defaultMapApp: "Apple Maps"
    )
}

#Preview("No Geofences") {
    NewSettingsView(
        activeGeofences: 0,
        defaultMapApp: "Google Maps"
    )
}
