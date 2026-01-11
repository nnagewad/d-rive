//
//  DériveApp.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-16.
//

import SwiftUI

@main
struct DeriveApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @State private var hasSelectedCity = CityService.shared.hasSelectedCity()

    var body: some Scene {
        WindowGroup {
            if hasSelectedCity {
                mainTabView
            } else {
                NavigationStack {
                    CityListView(hasSelectedCity: $hasSelectedCity)
                }
                .onChange(of: hasSelectedCity) { _, newValue in
                    if newValue {
                        // City was selected, start geofence monitoring
                        appDelegate.restartGeofenceMonitoring()
                    }
                }
            }
        }
    }

    private var mainTabView: some View {
        TabView {
            NavigationStack(path: $navigationCoordinator.navigationPath) {
                LocationListView()
                    .navigationDestination(for: MapDestination.self) { destination in
                        MapSelectionView(
                            latitude: destination.latitude,
                            longitude: destination.longitude,
                            locationName: destination.name,
                            group: destination.group,
                            city: destination.city,
                            country: destination.country
                        )
                    }
            }
            .tabItem {
                Label("Locations", systemImage: "mappin.and.ellipse")
            }

            NavigationStack {
                CityListView(hasSelectedCity: $hasSelectedCity)
                    .onChange(of: hasSelectedCity) { _, newValue in
                        if newValue {
                            // City changed, restart monitoring
                            appDelegate.restartGeofenceMonitoring()
                        }
                    }
            }
            .tabItem {
                Label("Cities", systemImage: "building.2")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .environmentObject(navigationCoordinator)
    }
}
