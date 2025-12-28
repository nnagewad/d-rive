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

    // Notification action identifiers - must match AppDelegate
    private let appleMapsActionID = "OPEN_APPLE_MAPS"
    private let googleMapsActionID = "OPEN_GOOGLE_MAPS"

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show as prominent banner with action buttons when app is foregrounded
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        logger.info("Notification action received: \(actionIdentifier)")

        // Extract destination coordinates from userInfo
        guard let lat = userInfo["destinationLat"] as? Double,
              let lon = userInfo["destinationLon"] as? Double else {
            logger.error("Missing destination coordinates in notification userInfo")
            completionHandler()
            return
        }

        // Handle different actions
        switch actionIdentifier {
        case appleMapsActionID:
            logger.info("Opening Apple Maps for destination: \(lat), \(lon)")
            MapNavigationService.shared.openAppleMaps(latitude: lat, longitude: lon)

        case googleMapsActionID:
            logger.info("Opening Google Maps for destination: \(lat), \(lon)")
            MapNavigationService.shared.openGoogleMaps(latitude: lat, longitude: lon)

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself (not an action button)
            logger.info("Notification tapped: \(response.notification.request.content.body)")

        default:
            logger.warning("Unknown action identifier: \(actionIdentifier)")
        }

        completionHandler()
    }
}
