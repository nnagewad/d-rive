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

// MARK: - Distance Calculation Helper
extension CLLocation {
    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return self.distance(from: location)
    }
}

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
}

struct GeofenceBundle: Codable {
    let version: String
    let defaultRadius: Double
    let geofences: [GeofenceConfiguration]
}

struct GeofenceInfo: Identifiable {
    let id: String
    let name: String
    let distance: Int
}

@MainActor
final class GeofenceManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = GeofenceManager()

    @Published var isInsideGeofence = false
    @Published var debugLogs: [String] = []
    @Published var currentDistance: String = "—"
    @Published var geofenceInfoList: [GeofenceInfo] = []

    private let manager = CLLocationManager()
    private var currentLocation: CLLocation?
    private let logger = Logger(subsystem: "com.derive.app", category: "GeofenceManager")
    private var isMonitoring = false
    private let maxLogEntries = 100

    // Store geofence configurations for notification handling
    private var activeGeofences: [String: GeofenceConfiguration] = [:]

    // Track which geofences we're currently inside
    private var insideGeofences: Set<String> = [] {
        didSet {
            isInsideGeofence = !insideGeofences.isEmpty
        }
    }

    // Track initial state determinations to send notifications
    private var pendingInitialStates: Set<String> = []

    // Track last notification time to prevent duplicates (region + GPS triggering together)
    private var lastNotificationTime: [String: Date] = [:]
    private let notificationCooldown: TimeInterval = 60  // 60 seconds between notifications

    override init() {
        super.init()
        manager.delegate = self
    }

    /// Start monitoring multiple geofences from configurations
    /// Uses hybrid approach: Region monitoring (works when terminated) + GPS (precise when running)
    func startMonitoring(configurations: [GeofenceConfiguration]) {
        guard !isMonitoring else {
            logger.warning("Already monitoring geofences")
            return
        }

        logger.info("Starting hybrid monitoring for \(configurations.count) geofences")

        // Request authorization
        manager.requestAlwaysAuthorization()

        // Configure for GPS accuracy
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10  // Update every 10 meters
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false

        isMonitoring = true

        // Clear any existing regions first
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }

        // Clear active configurations and inside state
        activeGeofences.removeAll()
        insideGeofences.removeAll()
        pendingInitialStates.removeAll()

        // Setup both region monitoring AND GPS tracking
        for config in configurations {
            // Store configuration
            activeGeofences[config.id] = config

            // Setup region monitoring (works when app is terminated)
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
            region.notifyOnExit = true

            // Start region monitoring
            manager.startMonitoring(for: region)

            logger.info("Configured geofence: \(config.name) [\(config.id)] - \(config.radius)m radius")
        }

        // Start continuous GPS location updates for precise tracking
        manager.startUpdatingLocation()

        logger.info("Successfully started hybrid monitoring (Region + GPS) for \(configurations.count) geofences")
        addDebugLog("📡 Started hybrid monitoring")
    }

    // MARK: - GPS Location Updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        currentLocation = location
        var geofenceDistances: [(id: String, name: String, distance: Int)] = []

        // Check distance from each geofence
        for (id, config) in activeGeofences {
            let center = CLLocationCoordinate2D(
                latitude: config.latitude,
                longitude: config.longitude
            )

            let distance = location.distance(from: center)
            let wasInside = insideGeofences.contains(id)
            let isInside = distance <= config.radius

            // Store distance for geofence list
            geofenceDistances.append((id: id, name: config.name, distance: Int(distance)))

            // Update current distance for UI
            currentDistance = "\(Int(distance))m / \(Int(config.radius))m"

            // Log distance for debugging
            let distanceLog = "📍 \(Int(distance))m from \(config.name)"
            logger.debug("Distance to \(config.name): \(Int(distance))m (radius: \(Int(config.radius))m)")
            addDebugLog(distanceLog)

            // State changed - entered geofence
            if !wasInside && isInside {
                insideGeofences.insert(id)
                let enterLog = "✅ ENTERED: \(config.name) at \(Int(distance))m"
                logger.info("✅ ENTERED: \(config.name) - Distance: \(Int(distance))m")
                addDebugLog(enterLog)
                notify(config)
            }
            // State changed - exited geofence
            else if wasInside && !isInside {
                insideGeofences.remove(id)
                let exitLog = "🚪 EXITED: \(config.name) at \(Int(distance))m"
                logger.info("🚪 EXITED: \(config.name) - Distance: \(Int(distance))m")
                addDebugLog(exitLog)
            }
        }

        // Update geofence info list sorted by distance
        geofenceInfoList = geofenceDistances
            .sorted { $0.distance < $1.distance }
            .map { GeofenceInfo(id: $0.id, name: $0.name, distance: $0.distance) }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        logger.info("Authorization changed: \(manager.authorizationStatus.rawValue)")
    }

    // MARK: - Region Monitoring (for terminated state)
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        insideGeofences.insert(region.identifier)

        // If activeGeofences is empty (app was terminated), reload configurations
        if activeGeofences.isEmpty {
            reloadGeofenceConfigurations()
        }

        guard let config = activeGeofences[region.identifier] else {
            logger.error("No configuration found for entered region: \(region.identifier)")
            return
        }

        logger.info("🌍 REGION ENTER: \(config.name)")
        addDebugLog("🌍 Region enter: \(config.name)")
        notify(config)
    }

    /// Reloads geofence configurations from disk (used when app is woken from terminated state)
    private func reloadGeofenceConfigurations() {
        do {
            let geofences = try GeofenceLoaderService.shared.loadGeofences()
            for config in geofences {
                activeGeofences[config.id] = config
            }
            logger.info("Reloaded \(geofences.count) geofence configurations after app wake")
        } catch {
            logger.error("Failed to reload geofences: \(error.localizedDescription)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        insideGeofences.remove(region.identifier)

        if let config = activeGeofences[region.identifier] {
            logger.info("🌍 REGION EXIT: \(config.name)")
            addDebugLog("🌍 Region exit: \(config.name)")
        }
    }

    func locationManager(_ manager: CLLocationManager,
                        monitoringDidFailFor region: CLRegion?,
                        withError error: Error) {
        logger.error("❌ Region monitoring failed for \(region?.identifier ?? "unknown"): \(error)")
        addDebugLog("❌ Region monitoring failed")
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false

        // Stop GPS updates
        manager.stopUpdatingLocation()

        // Stop region monitoring
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }

        // Clear state
        activeGeofences.removeAll()
        insideGeofences.removeAll()
        pendingInitialStates.removeAll()
    }

    private func addDebugLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logEntry = "[\(timestamp)] \(message)"

        debugLogs.insert(logEntry, at: 0)

        // Keep only the most recent entries
        if debugLogs.count > maxLogEntries {
            debugLogs.removeLast()
        }
    }

    private func notify(_ configuration: GeofenceConfiguration) {
        // Check cooldown to prevent duplicate notifications
        if let lastTime = lastNotificationTime[configuration.id] {
            let timeSinceLastNotification = Date().timeIntervalSince(lastTime)
            if timeSinceLastNotification < notificationCooldown {
                logger.info("⏱️ Skipping notification (cooldown) - sent \(Int(timeSinceLastNotification))s ago")
                addDebugLog("⏱️ Notification skipped (cooldown)")
                return
            }
        }

        lastNotificationTime[configuration.id] = Date()

        logger.info("🔔 Attempting to send notification for: \(configuration.name)")
        addDebugLog("🔔 Sending notification for \(configuration.name)")

        let content = UNMutableNotificationContent()
        content.title = "Dérive"
        content.body = "You're close to \(configuration.name)!"
        content.sound = .default

        // Include destination coordinates in userInfo for action handling
        content.userInfo = [
            "destinationLat": configuration.latitude,
            "destinationLon": configuration.longitude,
            "geofenceId": configuration.id,
            "geofenceName": configuration.name,
            "geofenceGroup": configuration.group,
            "geofenceCity": configuration.city,
            "geofenceCountry": configuration.country
        ]

        // Add trigger for background delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let error = error {
                    self.logger.error("❌ Notification failed: \(error.localizedDescription)")
                    self.addDebugLog("❌ Notification failed: \(error.localizedDescription)")
                } else {
                    self.logger.info("✅ Notification scheduled for: \(configuration.name)")
                    self.addDebugLog("✅ Notification scheduled")
                }
            }
        }
    }
}
