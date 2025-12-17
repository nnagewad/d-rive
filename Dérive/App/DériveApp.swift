//
//  DériveApp.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-16.
//

import SwiftUI
import UserNotifications

@main
struct DeriveApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

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
