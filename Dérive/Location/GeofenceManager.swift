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
        latitude: 51.615444181148085,
        longitude:  -0.17822624747039645,
        radius: 400,
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
        region.notifyOnExit = false

        manager.startMonitoring(for: region)
        manager.requestState(for: region)
        logger.info("Started monitoring geofence: \(configuration.identifier)")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        isInsideGeofence = true
        notify("Entered geofence")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        isInsideGeofence = false
        // No notification on exit
    }

    func locationManager(_ manager: CLLocationManager,
                        monitoringDidFailFor region: CLRegion?,
                        withError error: Error) {
        logger.error("Monitoring failed for region \(region?.identifier ?? "unknown"): \(error)")
    }

    func locationManager(_ manager: CLLocationManager,
                        didDetermineState state: CLRegionState,
                        for region: CLRegion) {
        logger.info("Determined state: \(state.rawValue) for region \(region.identifier)")

        switch state {
        case .inside:
            isInsideGeofence = true
            logger.info("Device is INSIDE geofence")
        case .outside:
            isInsideGeofence = false
            logger.info("Device is OUTSIDE geofence")
        case .unknown:
            logger.warning("Region state UNKNOWN - waiting for determination")
        @unknown default:
            logger.error("Unexpected region state")
        }
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
        content.sound = .default

        // Add trigger for background delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to deliver notification: \(error)")
            } else {
                self.logger.info("Notification delivered: \(message)")
            }
        }
    }
}
