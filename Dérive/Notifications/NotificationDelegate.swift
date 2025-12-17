//
//  NotificationDelegate.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-17.
//

import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Allow banner even when app is foregrounded
        completionHandler([.banner, .sound])
    }
}
