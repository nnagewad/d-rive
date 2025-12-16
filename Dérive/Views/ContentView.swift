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
    
    var body: some View {
        VStack(spacing: 16) {
            if let lat = locationManager.latitude,
               let lon = locationManager.longitude {
                Text("Lat: \(lat)")
                Text("Lon: \(lon)")
            } else {
                Text("Waiting for location…")
            }
            
            if geofenceManager.isInsideGeofence {
                Text("🟢 Inside geofence")
            } else {
                Text("🔴 Outside geofence")
            }
        }
        .padding()
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound]
            ) { _, _ in }

            locationManager.start()
            geofenceManager.startMonitoring()
        }
        .onDisappear {
            locationManager.stop()
        }
    }
}

#Preview {
    ContentView()
}
