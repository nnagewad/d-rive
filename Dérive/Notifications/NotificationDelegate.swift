//
//  NotificationDelegate.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-17.
//

import UIKit
import UserNotifications
import os.log

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    private let logger = Logger(subsystem: "com.derive.app", category: "NotificationDelegate")

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let appState = UIApplication.shared.applicationState
        let stateDescription = appState == .active ? "active" : (appState == .background ? "background" : "inactive")

        logger.info("📬 Notification arriving - App state: \(stateDescription)")
        logger.info("Notification content: \(notification.request.content.body)")

        // Suppress notifications only when app is active (foreground)
        // Allow notifications in all other states (background, inactive, terminated)
        if appState == .active {
            logger.info("❌ Suppressing notification - app is active")
            completionHandler([])
        } else {
            logger.info("✅ Showing notification - app is \(stateDescription)")
            completionHandler([.banner, .sound, .badge])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        logger.info("📬 Notification action received: \(actionIdentifier)")

        // Extract destination coordinates from userInfo (geofence notification)
        guard let lat = userInfo["destinationLat"] as? Double,
              let lon = userInfo["destinationLon"] as? Double else {
            logger.error("❌ Missing destination coordinates in notification userInfo")
            completionHandler()
            return
        }

        let name = userInfo["geofenceName"] as? String ?? "Unknown Location"
        let group = userInfo["geofenceGroup"] as? String ?? ""
        let city = userInfo["geofenceCity"] as? String ?? ""
        let country = userInfo["geofenceCountry"] as? String ?? ""

        // Handle notification tap (user tapped the notification body)
        if actionIdentifier == UNNotificationDefaultActionIdentifier {
            Task { @MainActor in
                // Check if user has a default map app set
                if let defaultMapApp = SettingsService.shared.defaultMapApp {
                    logger.info("🗺️ Notification tapped - opening \(defaultMapApp.displayName) for: \(name)")
                    MapNavigationService.shared.openMapApp(defaultMapApp, latitude: lat, longitude: lon)
                } else {
                    logger.info("🗺️ Notification tapped - navigating to map selection for: \(name)")
                    NavigationCoordinator.shared.navigateToMapSelection(
                        latitude: lat,
                        longitude: lon,
                        name: name,
                        group: group,
                        city: city,
                        country: country
                    )
                }
            }
        } else {
            logger.warning("⚠️ Unknown action identifier: \(actionIdentifier)")
        }

        completionHandler()
    }
}
