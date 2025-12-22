//
//  NotificationDelegate.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-17.
//

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
        // Allow banner even when app is foregrounded
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap when app is backgrounded/terminated
        logger.info("Notification received in background: \(response.notification.request.content.body)")
        completionHandler()
    }
}
