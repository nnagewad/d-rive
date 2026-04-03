//
//  HomeView.swift
//  Purpose: Root app view with spots list and navigation to curated lists and settings
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2026-04-01.
//

import SwiftUI
import SwiftData

private enum HomeDestination: Hashable {
    case curatedLists
    case settings
}

struct HomeView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @Environment(\.openURL) private var openURL
    var locationPermissionOverride: Bool? = nil

    @State private var path = NavigationPath()
    @State private var spotForSheet: SpotData?

    @Query(
        filter: #Predicate<SpotData> { spot in
            spot.list?.isDownloaded == true && spot.list?.notifyWhenNearby == true
        }
    ) private var spots: [SpotData]

    @ObservedObject private var permissionService = PermissionService.shared
    @ObservedObject private var locationManager = LocationManager.shared

    private var hasLocationPermission: Bool {
        if let override = locationPermissionOverride { return override }
        let status = permissionService.locationStatus
        return status == .authorizedAlways || status == .authorizedWhenInUse
    }

    private var sortedSpots: [SpotData] {
        guard locationManager.currentLocation != nil else {
            return spots.sorted { $0.name < $1.name }
        }
        return spots.sorted { spot1, spot2 in
            let d1 = locationManager.distance(to: spot1.latitude, longitude: spot1.longitude) ?? .infinity
            let d2 = locationManager.distance(to: spot2.latitude, longitude: spot2.longitude) ?? .infinity
            return d1 < d2
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if spots.isEmpty {
                    EmptyStateView(
                        systemImage: "ring",
                        title: "No nearby spots",
                        subtitle: "Start by adding a curated list",
                        buttonLabel: "Add a curated list"
                    ) {
                        path.append(HomeDestination.curatedLists)
                    }
                } else if !hasLocationPermission {
                    EmptyStateView(
                        systemImage: "location.slash.fill",
                        title: "Location Access disabled",
                        subtitle: "In order for Spots to work, enable Location Access",
                        buttonLabel: "iOS Settings"
                    ) {
                        openURL(URL(string: "app-settings:")!)
                    }
                } else {
                    NearbySpotsView(spots: sortedSpots)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                NavigationLink(value: HomeDestination.curatedLists) {
                                    Image(systemName: "plus")
                                }
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.circle)

                                NavigationLink(value: HomeDestination.settings) {
                                    Image(systemName: "gearshape.fill")
                                }
                                .buttonBorderShape(.circle)
                                .tint(.primary)
                            }
                        }
                }
            }
            .navigationTitle("Spots")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .curatedLists: LocationsView()
                case .settings: SettingsView()
                }
            }
        }
        .sheet(item: $spotForSheet) { spot in
            SpotDetailSheet(spot: spot) {
                navigationCoordinator.dismissSpotDetail()
                spotForSheet = nil
            }
        }
        .onAppear {
            Task { await permissionService.refreshPermissionStatus() }
            locationManager.start()
            if let spotId = navigationCoordinator.selectedSpotId, spotForSheet == nil {
                spotForSheet = DataService.shared.getSpot(byId: spotId)
            }
        }
        .onDisappear {
            locationManager.stop()
        }
        .onChange(of: navigationCoordinator.selectedSpotId) { _, newValue in
            if let spotId = newValue {
                spotForSheet = DataService.shared.getSpot(byId: spotId)
            } else {
                spotForSheet = nil
            }
        }
    }
}

// MARK: - Previews

#Preview("With Spots") {
    HomeView(locationPermissionOverride: true)
        .environmentObject(NavigationCoordinator.shared)
        .modelContainer(PreviewContainer.containerWithData)
}

#Preview("No Spots") {
    HomeView()
        .environmentObject(NavigationCoordinator.shared)
        .modelContainer(PreviewContainer.container)
}

#Preview("Location Disabled") {
    HomeView(locationPermissionOverride: false)
        .environmentObject(NavigationCoordinator.shared)
        .modelContainer(PreviewContainer.containerWithData)
}

#Preview("Dark") {
    HomeView(locationPermissionOverride: true)
        .environmentObject(NavigationCoordinator.shared)
        .modelContainer(PreviewContainer.containerWithData)
        .preferredColorScheme(.dark)
}

// MARK: - Preview Container

@MainActor
enum PreviewContainer {
    static var container: ModelContainer {
        let schema = Schema([CountryData.self, CityData.self, SpotCategoryData.self, CuratorData.self, CuratedListData.self, SpotData.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }

    static var containerWithData: ModelContainer {
        let container = self.container
        let context = container.mainContext

        let country = CountryData(name: "Canada")
        let city = CityData(name: "Toronto", countryData: country)
        let curator = CuratorData(name: "Local Expert", bio: "Toronto native")

        let list = CuratedListData(
            name: "Coffee Spots",
            listDescription: "Best coffee in Toronto",
            isDownloaded: true,
            notifyWhenNearby: true
        )
        list.city = city
        list.curator = curator

        let spots = [
            SpotData(name: "Sam James Coffee Bar", latitude: 43.6544, longitude: -79.4055),
            SpotData(name: "Pilot Coffee Roasters", latitude: 43.6465, longitude: -79.3963),
            SpotData(name: "Boxcar Social", latitude: 43.6677, longitude: -79.3901)
        ]
        spots.forEach { $0.list = list }

        context.insert(country)
        context.insert(city)
        context.insert(curator)
        context.insert(list)
        spots.forEach { context.insert($0) }

        return container
    }
}
