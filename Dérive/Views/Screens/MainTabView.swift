import SwiftUI
import SwiftData

// MARK: - Main Tab View

/// Main app container using native iOS TabView
/// iOS 26: Automatically gets liquid glass tab bar styling and dark mode support
struct MainTabView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var selectedTab: TabItem

    init(selectedTab: TabItem = .nearbySpots) {
        _selectedTab = State(initialValue: selectedTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NearbySpotsView()
                .tabItem {
                    Label(TabItem.nearbySpots.title, systemImage: TabItem.nearbySpots.icon)
                }
                .tag(TabItem.nearbySpots)

            CuratedListsView()
                .tabItem {
                    Label(TabItem.curatedLists.title, systemImage: TabItem.curatedLists.icon)
                }
                .tag(TabItem.curatedLists)

            NewSettingsView()
                .tabItem {
                    Label(TabItem.settings.title, systemImage: TabItem.settings.icon)
                }
                .tag(TabItem.settings)
        }
        .sheet(item: $navigationCoordinator.currentDestination) { destination in
            NearbyLocationSheet(destination: destination) {
                navigationCoordinator.dismissLocationSheet()
            }
        }
    }
}

// MARK: - Nearby Location Sheet

/// Sheet displayed when user taps a geofence notification
private struct NearbyLocationSheet: View {
    let destination: MapDestination
    let onClose: () -> Void

    @ObservedObject private var settingsService = SettingsService.shared
    @State private var showMapAppPicker = false

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: destination.name, onClose: onClose)

            ScrollView {
                VStack(spacing: Spacing.medium) {
                    infoCard

                    PrimaryButton(title: "Get Directions") {
                        handleGetDirections()
                    }
                    .padding(.horizontal, Spacing.medium)
                }
                .padding(.top, Spacing.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.backgroundGroupedPrimary)
        .sheet(isPresented: $showMapAppPicker) {
            MapAppPickerSheet(
                onSelect: { mapApp in
                    settingsService.defaultMapApp = mapApp
                    showMapAppPicker = false
                    openDirections(with: mapApp)
                }
            )
            .presentationDetents([.height(220)])
        }
    }

    private var infoCard: some View {
        GroupedCard {
            VStack(spacing: 0) {
                if !destination.group.isEmpty {
                    InfoRow(label: "Category", value: destination.group)
                }

                if !destination.city.isEmpty {
                    RowSeparator()
                    InfoRow(label: "City", value: destination.city)
                }

                if !destination.country.isEmpty {
                    RowSeparator()
                    InfoRow(label: "Country", value: destination.country)
                }
            }
        }
        .padding(.horizontal, Spacing.medium)
    }

    private func handleGetDirections() {
        if let mapApp = settingsService.defaultMapApp {
            openDirections(with: mapApp)
        } else {
            showMapAppPicker = true
        }
    }

    private func openDirections(with mapApp: MapApp) {
        MapNavigationService.shared.openMapApp(
            mapApp,
            latitude: destination.latitude,
            longitude: destination.longitude
        )
    }
}

// MARK: - Previews

#Preview("Main Tab View") {
    MainTabView()
        .environmentObject(NavigationCoordinator.shared)
        .modelContainer(PreviewContainer.containerWithData)
}

#Preview("Curated Lists Tab") {
    MainTabView(selectedTab: .curatedLists)
        .environmentObject(NavigationCoordinator.shared)
        .modelContainer(PreviewContainer.containerWithData)
}

#Preview("Settings Tab") {
    MainTabView(selectedTab: .settings)
        .environmentObject(NavigationCoordinator.shared)
        .modelContainer(PreviewContainer.containerWithData)
}
