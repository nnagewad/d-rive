import SwiftUI
import SwiftData
import CoreLocation

// MARK: - Nearby Spots View

/// Main screen showing nearby spots from downloaded curated lists
/// Tab 1 in the app navigation
struct NearbySpotsView: View {
    @Query(
        filter: #Predicate<SpotData> { spot in
            spot.list?.isDownloaded == true
        },
        sort: \SpotData.name
    ) private var spots: [SpotData]

    @ObservedObject private var permissionService = PermissionService.shared
    @State private var selectedSpot: SpotData?

    private var hasLocationPermission: Bool {
        let status = permissionService.locationStatus
        return status == .authorizedAlways || status == .authorizedWhenInUse
    }

    var body: some View {
        VStack(spacing: 0) {
            LargeTitleHeader(title: "Nearby Spots")

            if !hasLocationPermission {
                locationDisabledState
            } else if spots.isEmpty {
                emptyState
            } else {
                spotsList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.backgroundGroupedPrimary)
        .sheet(item: $selectedSpot) { spot in
            SpotDetailSheet(spot: spot) {
                selectedSpot = nil
            }
        }
        .onAppear {
            Task {
                await permissionService.refreshPermissionStatus()
            }
        }
    }

    // MARK: - Location Disabled State

    private var locationDisabledState: some View {
        EmptyState(
            title: "Location Access Required",
            subtitle: "Enable location in Settings to see nearby spots"
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyState(
            title: "No Nearby Spots",
            subtitle: "Download a curated list to see spots"
        )
    }

    // MARK: - Spots List

    private var spotsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ListSectionTitle(title: "Closest first")

                GroupedCard {
                    VStack(spacing: 0) {
                        ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
                            if index > 0 {
                                RowSeparator()
                            }
                            SpotRow(
                                name: spot.name,
                                category: spot.category,
                                onInfoTapped: {
                                    selectedSpot = spot
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, Spacing.medium)
            }
            .padding(.top, Spacing.small)
        }
    }
}

// MARK: - Spot Detail Sheet

private struct SpotDetailSheet: View {
    let spot: SpotData
    let onClose: () -> Void

    @ObservedObject private var settingsService = SettingsService.shared
    @State private var showMapAppPicker = false

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: spot.name, onClose: onClose)

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
                if !spot.category.isEmpty {
                    InfoRow(label: "Category", value: spot.category)
                }

                if let instagram = spot.instagramHandle {
                    RowSeparator()
                    LinkRow(label: "Instagram") {
                        openInstagram(instagram)
                    }
                }

                if let website = spot.websiteURL {
                    RowSeparator()
                    LinkRow(label: "Website") {
                        openWebsite(website)
                    }
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
            latitude: spot.latitude,
            longitude: spot.longitude
        )
    }

    private func openInstagram(_ handle: String) {
        let cleanHandle = handle.replacingOccurrences(of: "@", with: "")
        if let url = URL(string: "https://instagram.com/\(cleanHandle)") {
            UIApplication.shared.open(url)
        }
    }

    private func openWebsite(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Previews

#Preview("Empty State") {
    NearbySpotsView()
        .modelContainer(PreviewContainer.shared.container)
}

#Preview("With Spots") {
    NearbySpotsView()
        .modelContainer(PreviewContainer.shared.containerWithData)
}

// MARK: - Preview Container

@MainActor
enum PreviewContainer {
    static let shared = PreviewContainer.self

    static var container: ModelContainer {
        let schema = Schema([CityData.self, CuratorData.self, CuratedListData.self, SpotData.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }

    static var containerWithData: ModelContainer {
        let container = self.container
        let context = container.mainContext

        let city = CityData(name: "Toronto", country: "Canada")
        let curator = CuratorData(name: "Local Expert", bio: "Toronto native")

        let list = CuratedListData(
            name: "Coffee Spots",
            listDescription: "Best coffee in Toronto",
            isDownloaded: true,
            notifyWhenNearby: false
        )
        list.city = city
        list.curator = curator

        let spots = [
            SpotData(name: "Sam James Coffee Bar", category: "Coffee", latitude: 43.6544, longitude: -79.4055),
            SpotData(name: "Pilot Coffee Roasters", category: "Coffee", latitude: 43.6465, longitude: -79.3963),
            SpotData(name: "Boxcar Social", category: "Coffee", latitude: 43.6677, longitude: -79.3901)
        ]
        spots.forEach { $0.list = list }

        context.insert(city)
        context.insert(curator)
        context.insert(list)
        spots.forEach { context.insert($0) }

        return container
    }
}
