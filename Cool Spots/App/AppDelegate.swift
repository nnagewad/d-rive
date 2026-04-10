//
//  AppDelegate.swift
//  Cool Spots
//
//  Created by Nikin Nagewadia on 2025-12-17.
//

import UIKit
import UserNotifications
import os.log

final class AppDelegate: NSObject, UIApplicationDelegate {

    let notificationDelegate = NotificationDelegate()
    private let logger = Logger(subsystem: "com.nikin.spots", category: "AppDelegate")

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate

        let viewAction = UNNotificationAction(
            identifier: NotificationAction.viewOnPhone,
            title: "View on iPhone",
            options: .foreground
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
        // Without this, the delegate isn't set until after Supabase sync and
        // iOS may discard the region event before we're ready to handle it.
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
