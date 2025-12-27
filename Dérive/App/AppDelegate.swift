//
//  AppDelegate.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-17.
//

import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {

    let notificationDelegate = NotificationDelegate()

    // Notification category and action identifiers
    private let geofenceEnterCategoryID = "GEOFENCE_ENTER"
    private let appleMapsActionID = "OPEN_APPLE_MAPS"
    private let googleMapsActionID = "OPEN_GOOGLE_MAPS"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        UNUserNotificationCenter.current().delegate = notificationDelegate
        registerNotificationCategories()
        return true
    }

    private func registerNotificationCategories() {
        // Create actions
        let appleMapsAction = UNNotificationAction(
            identifier: appleMapsActionID,
            title: "Open in Apple Maps",
            options: [.foreground]
        )

        let googleMapsAction = UNNotificationAction(
            identifier: googleMapsActionID,
            title: "Open in Google Maps",
            options: [.foreground]
        )

        // Create category with actions
        let geofenceCategory = UNNotificationCategory(
            identifier: geofenceEnterCategoryID,
            actions: [appleMapsAction, googleMapsAction],
            intentIdentifiers: [],
            options: []
        )

        // Register the category
        UNUserNotificationCenter.current().setNotificationCategories([geofenceCategory])
    }
}
