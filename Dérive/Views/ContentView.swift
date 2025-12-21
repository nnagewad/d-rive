//
//  ContentView.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-16.
//

import SwiftUI
import UserNotifications
import os.log

struct ContentView: View {

    @StateObject private var locationManager = LocationManager()
    @StateObject private var geofenceManager = GeofenceManager()
    @Environment(\.scenePhase) private var scenePhase

    private let logger = Logger(subsystem: "com.derive.app", category: "ContentView")

    var body: some View {
        VStack(spacing: 16) {
            if let lat = locationManager.latitude,
               let lon = locationManager.longitude {
                Text(String(format: "Lat: %.5f", lat))
                Text(String(format: "Lon: %.5f", lon))
            } else {
                Text("Waiting for location…")
            }

            Text(
                geofenceManager.isInsideGeofence
                ? "🟢 Inside geofence"
                : "🔴 Outside geofence"
            )
        }
        .padding()
        .task {
            let center = UNUserNotificationCenter.current()

            do {
                let granted = try await center.requestAuthorization(
                    options: [.alert, .sound, .badge]
                )

                if granted {
                    // Verify settings are actually enabled
                    let settings = await center.notificationSettings()
                    guard settings.authorizationStatus == .authorized else {
                        logger.warning("Notifications not fully authorized")
                        return
                    }

                    geofenceManager.startMonitoring()  // Requests "always" authorization
                    // Wait briefly for authorization, then start location updates
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        locationManager.start()
                    }
                } else {
                    logger.warning("Notification permission denied")
                }
            } catch {
                logger.error("Failed to request notification authorization: \(error)")
            }
        }
        .onDisappear {
            locationManager.stop()
            geofenceManager.stopMonitoring()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                locationManager.setForegroundMode(true)
            case .inactive, .background:
                locationManager.setForegroundMode(false)
            @unknown default:
                break
            }
        }
    }
}


#Preview {
    ContentView()
}
