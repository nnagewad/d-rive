//
//  SpotsApp.swift
//  Purpose: App entry point and SwiftData model container setup
//  Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-16.
//

import SwiftUI
import SwiftData

@main
struct SpotsApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasCompletedInitialSync = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CountryData.self,
            CityData.self,
            SpotCategoryData.self,
            CuratorData.self,
            CuratedListData.self,
            SpotData.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }

        // Store may be corrupted — wipe and recreate (data re-syncs from Supabase)
        let logger = Logger(subsystem: "com.nikin.spots", category: "SpotsApp")
        logger.error("ModelContainer failed — attempting recovery by wiping local store")
        let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
        try? FileManager.default.removeItem(at: storeURL)

        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }

        // Last resort: in-memory store so the app remains functional
        logger.error("ModelContainer recovery failed — falling back to in-memory store")
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [memoryConfig])
    }()

    init() {
        DataService.shared.configure(with: sharedModelContainer)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
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
                    hasCompletedInitialSync = true
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    // Sync when returning to foreground (but not on initial launch)
                    if newPhase == .active && oldPhase == .background && hasCompletedInitialSync {
                        Task {
                            do {
                                try await DataService.shared.syncFromSupabase()
                            } catch {
                                print("Failed to sync from Supabase on foreground: \(error)")
                            }
                            // Reload geofences after sync to ensure they're up to date
                            reloadGeofences()
                        }
                    }
                }
        }
    }
}
