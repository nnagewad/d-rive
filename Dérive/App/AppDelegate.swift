//
//  AppDelegate.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-17.
//

import UIKit
import UserNotifications
import os.log

final class AppDelegate: NSObject, UIApplicationDelegate {

    let notificationDelegate = NotificationDelegate()
    private let logger = Logger(subsystem: "com.derive.app", category: "AppDelegate")

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        UNUserNotificationCenter.current().delegate = notificationDelegate

        return true
    }

    /// Start geofence monitoring after DataService is configured
    /// Called from DériveApp after data is ready
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
