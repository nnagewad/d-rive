//
//  GeofenceManager.swift
//  Purpose: background-safe region monitoring + notifications
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-16.
//

import CoreLocation
import Combine
import UserNotifications

@MainActor
final class GeofenceManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var isInsideGeofence = false

    private let manager = CLLocationManager()
    private var isMonitoring = false

    override init() {
        super.init()
        manager.delegate = self
        manager.requestAlwaysAuthorization()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        let center = CLLocationCoordinate2D(
            latitude: 51.61814,
            longitude: -0.18463
        )

        let region = CLCircularRegion(
            center: center,
            radius: 100,
            identifier: "TestGeofence"
        )

        region.notifyOnEntry = true
        region.notifyOnExit = true

        manager.startMonitoring(for: region)
        print("Started monitoring geofence")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        isInsideGeofence = true
        notify("Entered geofence")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        isInsideGeofence = false
        notify("Exited geofence")
    }

    private func notify(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Dérive"
        content.body = message

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
