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
                    options: [.alert, .sound]
                )

                if granted {
                    locationManager.start()
                    geofenceManager.startMonitoring()
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
    }
}


#Preview {
    ContentView()
}
