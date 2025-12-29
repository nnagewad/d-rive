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

struct GeofenceConfiguration: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let group: String
    let city: String
    let country: String
    let source: String
    let latitude: Double
    let longitude: Double
    let radius: Double
    let enabled: Bool

    // Legacy identifier for backward compatibility
    var identifier: String { id }

    nonisolated static let `default` = GeofenceConfiguration(
        id: "TestGeofence",
        name: "Test Location",
        group: "test",
        city: "Unknown",
        country: "Unknown",
        source: "manual",
        latitude: 43.539171192704025,
        longitude: -79.66271380779142,
        radius: 100,
        enabled: true
    )
}

struct GeofenceBundle: Codable {
    let version: String
    let defaultRadius: Double
    let geofences: [GeofenceConfiguration]
}

@MainActor
final class GeofenceManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var isInsideGeofence = false

    private let manager = CLLocationManager()
    private let logger = Logger(subsystem: "com.derive.app", category: "GeofenceManager")
    private var isMonitoring = false

    // Store geofence configurations for notification handling
    private var activeGeofences: [String: GeofenceConfiguration] = [:]

    // Notification category identifier - must match AppDelegate
    private let geofenceEnterCategoryID = "GEOFENCE_ENTER"

    override init() {
        super.init()
        manager.delegate = self
    }

    /// Start monitoring multiple geofences from configurations
    func startMonitoring(configurations: [GeofenceConfiguration]) {
        guard !isMonitoring else {
            logger.warning("Already monitoring geofences")
            return
        }

        logger.info("Starting monitoring for \(configurations.count) geofences")

        // Request authorization
        manager.requestAlwaysAuthorization()
        isMonitoring = true

        // Clear any existing regions first
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }

        // Clear active configurations
        activeGeofences.removeAll()

        // Start monitoring each enabled geofence
        for config in configurations {
            let center = CLLocationCoordinate2D(
                latitude: config.latitude,
                longitude: config.longitude
            )

            let region = CLCircularRegion(
                center: center,
                radius: config.radius,
                identifier: config.id
            )

            region.notifyOnEntry = true
            region.notifyOnExit = false

            // Store configuration for later notification handling
            activeGeofences[config.id] = config

            // Start monitoring
            manager.startMonitoring(for: region)
            manager.requestState(for: region)

            logger.info("Started monitoring: \(config.name) [\(config.id)]")
        }

        logger.info("Successfully started monitoring \(configurations.count) geofences")
    }

    /// Legacy method for backward compatibility - uses single default geofence
    func startMonitoring(configuration: GeofenceConfiguration = .default) {
        startMonitoring(configurations: [configuration])
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        isInsideGeofence = true

        // Look up the configuration for this region
        guard let config = activeGeofences[region.identifier] else {
            logger.error("No configuration found for entered region: \(region.identifier)")
            return
        }

        logger.info("Entered geofence: \(config.name)")
        notify(config)
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

    private func notify(_ configuration: GeofenceConfiguration) {
        let content = UNMutableNotificationContent()
        content.title = "Dérive"
        content.body = "You've arrived at \(configuration.name)!"
        content.sound = .default
        content.categoryIdentifier = geofenceEnterCategoryID

        // Include destination coordinates in userInfo for action handling
        content.userInfo = [
            "destinationLat": configuration.latitude,
            "destinationLon": configuration.longitude,
            "geofenceId": configuration.id,
            "geofenceName": configuration.name
        ]

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
                self.logger.info("Notification delivered for: \(configuration.name)")
            }
        }
    }
}
