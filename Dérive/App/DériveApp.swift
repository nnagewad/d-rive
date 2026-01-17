//
//  DériveApp.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-16.
//

import SwiftUI

@main
struct DeriveApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(navigationCoordinator)
        }
    }
}
