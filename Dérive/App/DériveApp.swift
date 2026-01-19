//
//  DériveApp.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-16.
//

import SwiftUI
import SwiftData

@main
struct DeriveApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CountryData.self,
            CityData.self,
            SpotCategoryData.self,
            CuratorData.self,
            CuratedListData.self,
            SpotData.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        DataService.shared.configure(with: sharedModelContainer)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(navigationCoordinator)
                .modelContainer(sharedModelContainer)
                .task {
                    // Sync data from Supabase on launch
                    do {
                        try await DataService.shared.syncFromSupabase()
                    } catch {
                        print("Failed to sync from Supabase: \(error)")
                    }
                    appDelegate.startGeofenceMonitoringIfNeeded()
                }
        }
    }
}
