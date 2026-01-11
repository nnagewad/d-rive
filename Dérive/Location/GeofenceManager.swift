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

    // Store ALL geofence configurations (for UI and distance calculations)
    private var allGeofences: [GeofenceConfiguration] = []

    // Store only the currently monitored geofences (max 20) for notification handling
    private var activeGeofences: [String: GeofenceConfiguration] = [:]

    // Track which geofence IDs are currently being monitored by Core Location
    private var monitoredGeofenceIds: Set<String> = []

    // Track location where we last updated monitored regions
    private var lastRegionUpdateLocation: CLLocation?

    // Re-evaluate which 20 geofences to monitor after moving this distance (meters)
    private let regionUpdateDistanceThreshold: Double = 2500

    // iOS Core Location limit for monitored regions
    private let maxMonitoredRegions = 20

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
    /// Only the nearest 20 geofences are monitored due to iOS Core Location limits.
    func startMonitoring(configurations: [GeofenceConfiguration]) {
        guard !isMonitoring else {
            logger.warning("Already monitoring geofences")
            return
        }

        logger.info("Starting hybrid monitoring for \(configurations.count) geofences (will monitor nearest \(self.maxMonitoredRegions))")

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

        // Clear state
        allGeofences = configurations
        activeGeofences.removeAll()
        monitoredGeofenceIds.removeAll()
        insideGeofences.removeAll()
        pendingInitialStates.removeAll()
        lastRegionUpdateLocation = nil

        // Log all geofences loaded
        for config in configurations {
            logger.debug("Loaded geofence: \(config.name) [\(config.id)] - \(config.radius)m radius")
        }

        // Register geofences immediately so they work even if app is terminated
        if let lastLocation = manager.location {
            // Use last known location to select nearest 20
            logger.info("Using last known location to select initial geofences")
            updateMonitoredRegions(for: lastLocation)
        } else {
            // No location available - register first 20 as fallback
            // These will be updated once we get an actual location
            logger.info("No location available, registering first \(self.maxMonitoredRegions) geofences as fallback")
            registerFallbackGeofences()
        }

        // Start significant location change monitoring (works when app is terminated)
        // This wakes the app when user travels several km, allowing us to update monitored geofences
        manager.startMonitoringSignificantLocationChanges()

        // Start continuous GPS location updates for precise tracking when app is running
        manager.startUpdatingLocation()

        logger.info("Started monitoring: regions + GPS + significant location changes")
        addDebugLog("📡 Started hybrid monitoring (\(configurations.count) locations)")
    }

    // MARK: - GPS Location Updates (also handles significant location changes)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // If allGeofences is empty, app was woken from terminated state - reload configurations
        if allGeofences.isEmpty {
            reloadGeofenceConfigurations()
        }

        currentLocation = location

        // Check if we need to update which regions are monitored
        let shouldUpdateRegions: Bool
        if lastRegionUpdateLocation == nil {
            // First location update - select initial nearest geofences
            shouldUpdateRegions = true
        } else if let lastLocation = lastRegionUpdateLocation {
            // Re-evaluate if we've moved significantly
            let distanceMoved = location.distance(from: lastLocation)
            shouldUpdateRegions = distanceMoved >= regionUpdateDistanceThreshold
        } else {
            shouldUpdateRegions = false
        }

        if shouldUpdateRegions {
            updateMonitoredRegions(for: location)
        }

        // Calculate distances for ALL geofences (for UI display)
        var geofenceDistances: [(id: String, name: String, distance: Int)] = []
        for config in allGeofences {
            let center = CLLocationCoordinate2D(latitude: config.latitude, longitude: config.longitude)
            let distance = location.distance(from: center)
            geofenceDistances.append((id: config.id, name: config.name, distance: Int(distance)))
        }

        // Update geofence info list sorted by distance (shows ALL locations)
        geofenceInfoList = geofenceDistances
            .sorted { $0.distance < $1.distance }
            .map { GeofenceInfo(id: $0.id, name: $0.name, distance: $0.distance) }

        // Check entry/exit only for actively monitored geofences
        for (id, config) in activeGeofences {
            let center = CLLocationCoordinate2D(latitude: config.latitude, longitude: config.longitude)
            let distance = location.distance(from: center)
            let wasInside = insideGeofences.contains(id)
            let isInside = distance <= config.radius

            // Update current distance for UI (show nearest monitored)
            if id == geofenceInfoList.first?.id {
                currentDistance = "\(Int(distance))m / \(Int(config.radius))m"
            }

            // Log distance for debugging
            logger.debug("Distance to \(config.name): \(Int(distance))m (radius: \(Int(config.radius))m)")

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
            allGeofences = geofences

            // Rebuild activeGeofences from currently monitored regions
            let monitoredIds = Set(manager.monitoredRegions.map { $0.identifier })
            for config in geofences where monitoredIds.contains(config.id) {
                activeGeofences[config.id] = config
            }
            monitoredGeofenceIds = monitoredIds

            logger.info("Reloaded \(geofences.count) geofence configurations after app wake (\(monitoredIds.count) monitored)")
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

        // Stop all location updates
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()

        // Stop region monitoring
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }

        // Clear state
        allGeofences.removeAll()
        activeGeofences.removeAll()
        monitoredGeofenceIds.removeAll()
        insideGeofences.removeAll()
        pendingInitialStates.removeAll()
        lastRegionUpdateLocation = nil
    }

    // MARK: - Dynamic Region Management

    /// Updates which geofences are monitored based on proximity to the given location.
    /// Only the nearest 20 geofences will be monitored (iOS Core Location limit).
    private func updateMonitoredRegions(for location: CLLocation) {
        // Calculate distances and sort by proximity
        let sortedByDistance = allGeofences.map { config -> (config: GeofenceConfiguration, distance: Double) in
            let center = CLLocationCoordinate2D(latitude: config.latitude, longitude: config.longitude)
            let distance = location.distance(from: center)
            return (config, distance)
        }.sorted { $0.distance < $1.distance }

        // Take the nearest 20 (or all if fewer than 20)
        let nearest = Array(sortedByDistance.prefix(maxMonitoredRegions))
        let nearestIds = Set(nearest.map { $0.config.id })

        // Check if the set of nearest geofences has changed
        if nearestIds == monitoredGeofenceIds {
            logger.debug("Nearest \(nearestIds.count) geofences unchanged, skipping region update")
            return
        }

        logger.info("Updating monitored regions: \(nearestIds.count) nearest geofences")

        // Find which regions to stop and start monitoring
        let toStop = monitoredGeofenceIds.subtracting(nearestIds)
        let toStart = nearestIds.subtracting(monitoredGeofenceIds)

        // Stop monitoring regions that are no longer in the nearest set
        for regionId in toStop {
            if let region = manager.monitoredRegions.first(where: { $0.identifier == regionId }) {
                manager.stopMonitoring(for: region)
                activeGeofences.removeValue(forKey: regionId)
                logger.debug("Stopped monitoring: \(regionId)")
            }
        }

        // Start monitoring new nearest regions
        for (config, distance) in nearest where toStart.contains(config.id) {
            let center = CLLocationCoordinate2D(latitude: config.latitude, longitude: config.longitude)
            let region = CLCircularRegion(center: center, radius: config.radius, identifier: config.id)
            region.notifyOnEntry = true
            region.notifyOnExit = true

            manager.startMonitoring(for: region)
            activeGeofences[config.id] = config
            logger.info("Started monitoring: \(config.name) (\(Int(distance))m away)")
        }

        // Update tracked state
        monitoredGeofenceIds = nearestIds
        lastRegionUpdateLocation = location

        addDebugLog("📍 Monitoring \(monitoredGeofenceIds.count) nearest geofences")
    }

    /// Registers the first N geofences as a fallback when no location is available.
    /// These will be replaced with the nearest geofences once we get a location update.
    private func registerFallbackGeofences() {
        let fallbackGeofences = Array(allGeofences.prefix(maxMonitoredRegions))

        for config in fallbackGeofences {
            let center = CLLocationCoordinate2D(latitude: config.latitude, longitude: config.longitude)
            let region = CLCircularRegion(center: center, radius: config.radius, identifier: config.id)
            region.notifyOnEntry = true
            region.notifyOnExit = true

            manager.startMonitoring(for: region)
            activeGeofences[config.id] = config
            monitoredGeofenceIds.insert(config.id)
            logger.debug("Fallback registered: \(config.name)")
        }

        addDebugLog("📍 Registered \(fallbackGeofences.count) fallback geofences")
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
