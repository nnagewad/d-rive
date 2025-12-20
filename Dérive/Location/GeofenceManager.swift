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
import os.log

struct GeofenceConfiguration: Sendable {
    let latitude: Double
    let longitude: Double
    let radius: Double
    let identifier: String

    nonisolated static let `default` = GeofenceConfiguration(
        latitude: 51.61814,
        longitude: -0.18463,
        radius: 100,
        identifier: "TestGeofence"
    )
}

@MainActor
final class GeofenceManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var isInsideGeofence = false

    private let manager = CLLocationManager()
    private let logger = Logger(subsystem: "com.derive.app", category: "GeofenceManager")
    private var isMonitoring = false

    override init() {
        super.init()
        manager.delegate = self
    }

    func startMonitoring(configuration: GeofenceConfiguration = .default) {
        guard !isMonitoring else { return }

        manager.requestAlwaysAuthorization()
        isMonitoring = true

        let center = CLLocationCoordinate2D(
            latitude: configuration.latitude,
            longitude: configuration.longitude
        )

        let region = CLCircularRegion(
            center: center,
            radius: configuration.radius,
            identifier: configuration.identifier
        )

        region.notifyOnEntry = true
        region.notifyOnExit = true

        manager.startMonitoring(for: region)
        logger.info("Started monitoring geofence: \(configuration.identifier)")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        isInsideGeofence = true
        notify("Entered geofence")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        isInsideGeofence = false
        notify("Exited geofence")
    }

    func locationManager(_ manager: CLLocationManager,
                        monitoringDidFailFor region: CLRegion?,
                        withError error: Error) {
        logger.error("Monitoring failed for region \(region?.identifier ?? "unknown"): \(error)")
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false

        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
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
