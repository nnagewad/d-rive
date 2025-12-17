//
//  ContentView.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-16.
//

import SwiftUI
import UserNotifications

struct ContentView: View {

    @StateObject private var locationManager = LocationManager()
    @StateObject private var geofenceManager = GeofenceManager()

    private let notificationDelegate = NotificationDelegate()

    var body: some View {
        VStack(spacing: 16) {
            if let lat = locationManager.latitude,
               let lon = locationManager.longitude {
                Text("Lat: \(lat)")
                Text("Lon: \(lon)")
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
            center.delegate = notificationDelegate

            let granted = try? await center.requestAuthorization(
                options: [.alert, .sound]
            )

            if granted == true {
                locationManager.start()
                geofenceManager.startMonitoring()
            }
        }
        .onDisappear {
            locationManager.stop()
        }
    }
}


#Preview {
    ContentView()
}
