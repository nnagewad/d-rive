//
//  SpotsApp.swift
//  Purpose: App entry point and SwiftData model container setup
//  Cool Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-16.
//

import SwiftUI
import SwiftData
import OSLog

@main
struct SpotsApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasCompletedInitialSync = false

    // Container is owned by AppDelegate so DataService is configured before
    // any CLLocationManager events fire on terminated-state wake.
    var sharedModelContainer: ModelContainer { appDelegate.sharedModelContainer }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(navigationCoordinator)
                .modelContainer(sharedModelContainer)
                .task {
                    // Start monitoring immediately from local data so geofences
                    // are active before the Supabase sync completes.
                    appDelegate.startGeofenceMonitoringIfNeeded()

                    do {
                        try await DataService.shared.syncFromSupabase()
                    } catch {
                        print("Failed to sync from Supabase: \(error)")
                    }

                    // Reload after sync in case spots changed on the server.
                    reloadGeofences()
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
