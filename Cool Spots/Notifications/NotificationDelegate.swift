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

    private let logger = Logger(subsystem: "com.nikin.spots", category: "NotificationDelegate")

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

        // Extract spot ID from userInfo (geofence notification)
        guard let spotId = userInfo["geofenceId"] as? String else {
            logger.error("❌ Missing geofenceId in notification userInfo")
            completionHandler()
            return
        }

        let name = userInfo["geofenceName"] as? String ?? "Unknown Location"
        let isGrouped = userInfo["isGrouped"] as? Bool ?? false

        // Handle notification tap
        if actionIdentifier == UNNotificationDefaultActionIdentifier {
            Task { @MainActor in
                if isGrouped {
                    logger.info("🗺️ Grouped notification tapped - navigating home")
                    NavigationCoordinator.shared.clearNavigation()
                } else {
                    logger.info("🗺️ Notification tapped - showing spot detail for: \(name)")
                    NavigationCoordinator.shared.showSpotDetail(spotId: spotId)
                }
            }
        } else {
            logger.warning("⚠️ Unknown action identifier: \(actionIdentifier)")
        }

        completionHandler()
    }
}
