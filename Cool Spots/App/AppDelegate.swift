//
//  AppDelegate.swift
//  Purpose: UIKit application lifecycle, notification setup, and early data bootstrap
//  Cool Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-17.
//

import UIKit
import SwiftData
import UserNotifications
import os.log

final class AppDelegate: NSObject, UIApplicationDelegate {

    let notificationDelegate = NotificationDelegate()
    private let logger = Logger(subsystem: "com.nikin.spots", category: "AppDelegate")

    /// Shared model container created here so DataService is configured before
    /// any CLLocationManager region events arrive (which can fire immediately on
    /// app wake from terminated state, before SwiftUI's scene is set up).
    let sharedModelContainer: ModelContainer = {
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
        let logger = Logger(subsystem: "com.nikin.spots", category: "AppDelegate")
        logger.error("ModelContainer failed — attempting recovery by wiping local store")
        let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
        try? FileManager.default.removeItem(at: storeURL)

        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }

        logger.error("ModelContainer recovery failed — falling back to in-memory store")
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [memoryConfig])
    }()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        // Configure DataService before anything else so geofence reload has a
        // valid context if iOS delivers a region event immediately on wake.
        DataService.shared.configure(with: sharedModelContainer)

        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate

        // No .foreground option — allows the action to appear on Apple Watch mirrored
        // notifications. The app opens via NavigationCoordinator in didReceive.
        let viewAction = UNNotificationAction(
            identifier: NotificationAction.viewOnPhone,
            title: "View on iPhone",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: NotificationCategory.geofence,
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])

        // Initialize GeofenceManager immediately so CLLocationManager receives
        // region events when the app is woken from a terminated state.
        _ = GeofenceManager.shared

        return true
    }

    /// Start geofence monitoring after DataService is configured
    /// Called from SpotsApp after data is ready
    @MainActor
    func startGeofenceMonitoringIfNeeded() {
        guard GeofenceLoaderService.shared.canLoadGeofences() else {
            logger.info("No active geofences yet, skipping monitoring")
            return
        }

        do {
            let geofences = try GeofenceLoaderService.shared.loadGeofences()
            GeofenceManager.shared.startMonitoring(configurations: geofences)
            logger.info("Started geofence monitoring for \(geofences.count) spots")
        } catch {
            logger.error("Failed to load geofences: \(error.localizedDescription)")
        }
    }
}

// MARK: - Global function to reload geofences

/// Call this when lists are downloaded or notification settings change
@MainActor
func reloadGeofences() {
    GeofenceLoaderService.shared.reloadAndRestartMonitoring()
}
