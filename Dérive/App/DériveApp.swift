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

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationCoordinator.navigationPath) {
                CityListView()
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
            .environmentObject(navigationCoordinator)
        }
    }
}
