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
            openAppleMaps(latitude: lat, longitude: lon)

        case googleMapsActionID:
            logger.info("Opening Google Maps for destination: \(lat), \(lon)")
            openGoogleMaps(latitude: lat, longitude: lon)

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself (not an action button)
            logger.info("Notification tapped: \(response.notification.request.content.body)")

        default:
            logger.warning("Unknown action identifier: \(actionIdentifier)")
        }

        completionHandler()
    }

    // MARK: - Map URL Helpers

    private func openAppleMaps(latitude: Double, longitude: Double) {
        // Apple Maps URL with walking directions
        let urlString = "https://maps.apple.com/?saddr=Current+Location&daddr=\(latitude),\(longitude)&dirflg=w"

        guard let url = URL(string: urlString) else {
            logger.error("Invalid Apple Maps URL")
            return
        }

        UIApplication.shared.open(url) { success in
            if success {
                self.logger.info("Opened Apple Maps successfully")
            } else {
                self.logger.error("Failed to open Apple Maps")
            }
        }
    }

    private func openGoogleMaps(latitude: Double, longitude: Double) {
        // Try Google Maps app first
        let appURLString = "comgooglemaps://?daddr=\(latitude),\(longitude)&directionsmode=walking"

        if let appURL = URL(string: appURLString),
           UIApplication.shared.canOpenURL(appURL) {
            // Google Maps app is installed
            UIApplication.shared.open(appURL) { success in
                if success {
                    self.logger.info("Opened Google Maps app successfully")
                } else {
                    self.logger.error("Failed to open Google Maps app")
                }
            }
        } else {
            // Fallback to web version
            let webURLString = "https://www.google.com/maps/dir/?api=1&destination=\(latitude),\(longitude)&travelmode=walking"

            guard let webURL = URL(string: webURLString) else {
                logger.error("Invalid Google Maps web URL")
                return
            }

            UIApplication.shared.open(webURL) { success in
                if success {
                    self.logger.info("Opened Google Maps web version successfully")
                } else {
                    self.logger.error("Failed to open Google Maps web version")
                }
            }
        }
    }
}
