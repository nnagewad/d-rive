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

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        UNUserNotificationCenter.current().delegate = notificationDelegate
        return true
    }
}
