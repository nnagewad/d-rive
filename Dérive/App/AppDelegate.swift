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

        // Request notification authorization and start geofence monitoring
        Task { @MainActor in
            await requestNotificationAuthorizationAndStartMonitoring()
        }

        return true
    }

    @MainActor
    private func requestNotificationAuthorizationAndStartMonitoring() async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

            if granted {
                logger.info("Notification authorization granted")
                startGeofenceMonitoring()
            } else {
                logger.warning("Notification authorization denied")
            }
        } catch {
            logger.error("Failed to request notification authorization: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func startGeofenceMonitoring() {
        // Only start monitoring if a city is selected and downloaded
        guard GeofenceLoaderService.shared.canLoadGeofences() else {
            logger.info("No city selected yet, skipping geofence monitoring")
            return
        }

        do {
            let geofences = try GeofenceLoaderService.shared.loadGeofences()
            GeofenceManager.shared.startMonitoring(configurations: geofences)
            logger.info("Started geofence monitoring for \(geofences.count) locations")
        } catch {
            logger.error("Failed to load geofences: \(error.localizedDescription)")
        }
    }

    /// Called when a city is selected to start monitoring
    @MainActor
    func restartGeofenceMonitoring() {
        // Stop any existing monitoring first
        GeofenceManager.shared.stopMonitoring()

        // Start fresh with new city
        startGeofenceMonitoring()
    }
}
