import SwiftUI
import SwiftData
import CoreLocation
import UIKit

// MARK: - Nearby Spots View

/// Main screen showing nearby spots from downloaded curated lists
/// Tab 1 in the app navigation
struct NearbySpotsView: View {
    @Query(
        filter: #Predicate<SpotData> { spot in
            spot.list?.isDownloaded == true && spot.list?.notifyWhenNearby == true
        }
    ) private var spots: [SpotData]

    @ObservedObject private var permissionService = PermissionService.shared
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var selectedSpot: SpotData?
    @State private var showUpdatesSheet: Bool = false

    private var hasLocationPermission: Bool {
        let status = permissionService.locationStatus
        return status == .authorizedAlways || status == .authorizedWhenInUse
    }

    /// Spots sorted by distance from current location
    private var sortedSpots: [SpotData] {
        guard locationManager.currentLocation != nil else {
            return spots.sorted { $0.name < $1.name }
        }

        return spots.sorted { spot1, spot2 in
            let distance1 = locationManager.distance(to: spot1.latitude, longitude: spot1.longitude) ?? .infinity
            let distance2 = locationManager.distance(to: spot2.latitude, longitude: spot2.longitude) ?? .infinity
            return distance1 < distance2
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedSpots.isEmpty {
                    emptyState
                } else if !hasLocationPermission {
                    locationDisabledState
                } else {
                    spotsList
                }
            }
            .navigationTitle("Nearby Spots")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Updates") {
                        showUpdatesSheet = true
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
            }
        }
        .sheet(item: $selectedSpot) { spot in
            SpotDetailSheet(spot: spot) {
                selectedSpot = nil
            }
        }
        .sheet(isPresented: $showUpdatesSheet) {
            UpdatesSheetView()
        }
        .onAppear {
            Task {
                await permissionService.refreshPermissionStatus()
            }
            locationManager.start()
        }
        .onDisappear {
            locationManager.stop()
        }
    }

    // MARK: - Location Disabled State

    private var locationDisabledState: some View {
        ContentUnavailableView {
            Label("Location Access Required", systemImage: "location.slash")
        } description: {
            Text("Enable location in Settings to see nearby spots")
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Nearby Spots", systemImage: "mappin.slash")
        } description: {
            Text("Add a Curated List to see nearby spots")
        }
    }

    // MARK: - Spots List

    private var spotsList: some View {
        List {
            Section {
                ForEach(sortedSpots) { spot in
                    Button {
                        selectedSpot = spot
                    } label: {
                        LabeledContent {
                            Image(systemName: "info.circle")
                                .foregroundStyle(Color.accentBlue)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(spot.name)
                                    .foregroundStyle(Color.labelPrimary)
                                if !spot.category.isEmpty {
                                    Text(spot.category)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.labelSecondary)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Closest first")
            }
        }
        .listStyle(.insetGrouped)
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
