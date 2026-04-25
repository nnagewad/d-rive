//
//  GeofenceManager.swift
//  Purpose: background-safe region monitoring + notifications
//  Cool Spots
//
//  Created by Nikin Nagewadia on 2025-12-16.
//

import CoreLocation
import Combine
import UserNotifications
import UIKit
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
final class GeofenceManager: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {

    static let shared = GeofenceManager()

    @Published var geofenceInfoList: [GeofenceInfo] = []

    private let manager = CLLocationManager()
    private var currentLocation: CLLocation?
    private let logger = Logger(subsystem: "com.nikin.spots", category: "GeofenceManager")
    private var isMonitoring = false

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

    // Maximum age of a cached location to be considered valid for GPS cross-checks
    private let maxLocationAge: TimeInterval = 30

    // Track which geofences we're currently inside — in-memory only.
    // Preserved through stopMonitoring+startMonitoring reload cycles (within a session) so
    // didDetermineState(.inside) sees wasInside=true and skips re-notification on foreground resume.
    // Cleared on every app restart so background/terminated entry events always fire a notification.
    private var insideGeofences: Set<String> = []

    // Track last notification time to prevent duplicates and suppress re-notification when
    // the app is relaunched while the user is still inside a geofence.
    // Persisted so the cooldown survives app restarts.
    private static let lastNotificationTimeKey = "GeofenceManager.lastNotificationTime"
    private var lastNotificationTime: [String: Date] = [:]
    private let notificationCooldown: TimeInterval = 2 * 3600  // 2 hours between notifications

    override init() {
        if let data = UserDefaults.standard.data(forKey: Self.lastNotificationTimeKey),
           let dict = try? JSONDecoder().decode([String: Date].self, from: data) {
            lastNotificationTime = dict
        }
        super.init()
        manager.delegate = self
        // Remove stale insideGeofences key left by a previous app version
        UserDefaults.standard.removeObject(forKey: "GeofenceManager.insideGeofences")
    }

    private func persistLastNotificationTime() {
        if let data = try? JSONEncoder().encode(lastNotificationTime) {
            UserDefaults.standard.set(data, forKey: Self.lastNotificationTimeKey)
        }
    }

    /// Returns a verified GPS location for cross-checking region events, or nil if none is available.
    /// Only uses currentLocation (set by LocationManager with ≤50m accuracy) — never falls back
    /// to manager.location which uses cell towers/WiFi and can be hundreds of metres off.
    private var verifiedGPSLocation: CLLocation? {
        guard let loc = currentLocation else { return nil }
        guard Date().timeIntervalSince(loc.timestamp) <= maxLocationAge else { return nil }
        return loc
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

        // Configure for background region monitoring
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true

        isMonitoring = true

        allGeofences = configurations
        activeGeofences.removeAll()
        monitoredGeofenceIds.removeAll()
        lastRegionUpdateLocation = nil

        // Rebuild state from regions iOS is already monitoring (persisted across termination).
        // Do NOT stop-then-restart existing regions — that discards pending didEnterRegion
        // events already queued by iOS before startMonitoring runs.
        let configById = Dictionary(uniqueKeysWithValues: configurations.map { ($0.id, $0) })
        for region in manager.monitoredRegions {
            if let config = configById[region.identifier] {
                activeGeofences[region.identifier] = config
                monitoredGeofenceIds.insert(region.identifier)
                logger.debug("Retained existing region: \(config.name)")
            } else {
                // Stale region no longer in configurations — remove it
                manager.stopMonitoring(for: region)
                logger.debug("Removed stale region: \(region.identifier)")
            }
        }

        for config in configurations {
            logger.debug("Loaded geofence: \(config.name) [\(config.id)] - \(config.radius)m radius")
        }

        // Register/update nearest geofences based on current location
        if let lastLocation = manager.location {
            logger.info("Using last known location to select initial geofences")
            updateMonitoredRegions(for: lastLocation)
        } else {
            logger.info("No location available, registering first \(self.maxMonitoredRegions) geofences as fallback")
            registerFallbackGeofences()
        }

        // Seed insideGeofences with any active geofences the user is currently inside.
        // Without this, the first handleLocationUpdate call after startMonitoring would see
        // wasInside=false for newly added geofences and fire an unwanted notification.
        let seedLocation = currentLocation ?? manager.location
        if let seedLoc = seedLocation {
            for (id, config) in activeGeofences where !insideGeofences.contains(id) {
                let center = CLLocationCoordinate2D(latitude: config.latitude, longitude: config.longitude)
                if seedLoc.distance(from: center) <= config.radius {
                    insideGeofences.insert(id)
                    logger.debug("Pre-seeding inside on start: \(config.name)")
                }
            }
        }

        // Start significant location change monitoring (works when app is terminated)
        // This wakes the app when user travels several km, allowing us to update monitored geofences
        manager.startMonitoringSignificantLocationChanges()

        logger.info("Started monitoring: regions + significant location changes")
    }

    // MARK: - GPS Location Updates (significant location changes when background/terminated)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // If allGeofences is empty, app was woken from terminated state - reload configurations
        if allGeofences.isEmpty {
            reloadGeofenceConfigurations()
        }

        handleLocationUpdate(location)
    }

    /// Process a location update from any source (significant changes or continuous GPS via LocationManager).
    /// Called frequently when the app is active so geofence entry/exit is detected without relying
    /// solely on iOS region monitoring, which can be delayed by several minutes.
    func handleLocationUpdate(_ location: CLLocation) {
        currentLocation = location

        // Check if we need to update which regions are monitored
        let shouldUpdateRegions: Bool
        if lastRegionUpdateLocation == nil {
            shouldUpdateRegions = true
        } else if let lastLocation = lastRegionUpdateLocation {
            let distanceMoved = location.distance(from: lastLocation)
            shouldUpdateRegions = distanceMoved >= regionUpdateDistanceThreshold
        } else {
            shouldUpdateRegions = false
        }

        if shouldUpdateRegions {
            updateMonitoredRegions(for: location)
        }

        // Calculate distances for ALL geofences (for UI display)
        geofenceInfoList = allGeofences
            .map { config -> GeofenceInfo in
                let center = CLLocationCoordinate2D(latitude: config.latitude, longitude: config.longitude)
                let distance = Int(location.distance(from: center))
                return GeofenceInfo(id: config.id, name: config.name, distance: distance)
            }
            .sorted { $0.distance < $1.distance }

        // Check entry/exit only for actively monitored geofences
        for (id, config) in activeGeofences {
            let center = CLLocationCoordinate2D(latitude: config.latitude, longitude: config.longitude)
            let distance = location.distance(from: center)
            let wasInside = insideGeofences.contains(id)

            logger.debug("Distance to \(config.name): \(Int(distance))m (radius: \(Int(config.radius))m)")

            // Require distance + GPS error to be within radius so inaccurate fixes don't
            // fire spurious entries. horizontalAccuracy is -1 when unknown; clamp to 0.
            let accuracy = max(location.horizontalAccuracy, 0)
            let isInside = (distance + accuracy) <= config.radius

            if !wasInside && isInside {
                insideGeofences.insert(id)
                logger.info("✅ ENTERED: \(config.name) - Distance: \(Int(distance))m")
                notify(config)
            } else if wasInside && !isInside {
                insideGeofences.remove(id)
                logger.info("🚪 EXITED: \(config.name) - Distance: \(Int(distance))m")
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        logger.info("Authorization changed: \(manager.authorizationStatus.rawValue)")
    }

    // MARK: - Region Monitoring (for terminated state)
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let wasInside = insideGeofences.contains(region.identifier)
        insideGeofences.insert(region.identifier)

        // If GPS already tracked this entry, skip to avoid duplicates
        if wasInside {
            logger.debug("🌍 REGION ENTER (already tracked): \(region.identifier)")
            return
        }

        // If activeGeofences is empty (app was terminated), reload configurations
        if activeGeofences.isEmpty {
            reloadGeofenceConfigurations()
        }

        guard let config = activeGeofences[region.identifier] else {
            logger.error("No configuration found for entered region: \(region.identifier)")
            return
        }

        // Cross-check with the best available location. Prefer a fresh verified GPS fix;
        // fall back to manager.location (last known) so cold-launch deferred entry events
        // are blocked when the user is no longer near the spot. Only trust iOS blindly
        // when no location is available at all.
        let locationToCheck = verifiedGPSLocation ?? manager.location
        if let gpsLocation = locationToCheck {
            let center = CLLocationCoordinate2D(latitude: config.latitude, longitude: config.longitude)
            let gpsDistance = gpsLocation.distance(from: center)
            let allowedDistance = config.radius + max(gpsLocation.horizontalAccuracy, 0)
            guard gpsDistance <= allowedDistance else {
                logger.info("🌍 REGION ENTER but location says \(Int(gpsDistance))m away (radius: \(Int(config.radius))m + \(Int(gpsLocation.horizontalAccuracy))m accuracy), ignoring")
                insideGeofences.remove(region.identifier)
                return
            }
        }

        logger.info("🌍 REGION ENTER: \(config.name)")
        notify(config)
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        // If activeGeofences is empty (app was terminated), reload configurations
        if activeGeofences.isEmpty {
            reloadGeofenceConfigurations()
        }

        guard let config = activeGeofences[region.identifier] else {
            logger.debug("No configuration found for region state: \(region.identifier)")
            return
        }

        switch state {
        case .inside:
            // Use GPS to validate region state accuracy if a fresh fix is available.
            if let gpsLocation = verifiedGPSLocation {
                let center = CLLocationCoordinate2D(latitude: config.latitude, longitude: config.longitude)
                let gpsDistance = gpsLocation.distance(from: center)
                let allowedDistance = config.radius + gpsLocation.horizontalAccuracy
                guard gpsDistance <= allowedDistance else {
                    logger.info("🌍 REGION STATE INSIDE but GPS says \(Int(gpsDistance))m away (radius: \(Int(config.radius))m + \(Int(gpsLocation.horizontalAccuracy))m accuracy), ignoring: \(config.name)")
                    insideGeofences.remove(region.identifier)
                    return
                }
            }
            // Only update tracking state — notifications fire exclusively from didEnterRegion.
            // requestState is called on monitoring start, so .inside here means the user
            // was already inside when monitoring began, not that they just crossed the boundary.
            insideGeofences.insert(region.identifier)
            logger.debug("🌍 REGION STATE INSIDE (tracking only): \(config.name)")

        case .outside:
            insideGeofences.remove(region.identifier)
            logger.debug("🌍 REGION STATE OUTSIDE: \(config.name)")

        case .unknown:
            logger.debug("🌍 REGION STATE UNKNOWN: \(config.name)")

        @unknown default:
            break
        }
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
        }
    }

    func locationManager(_ manager: CLLocationManager,
                        monitoringDidFailFor region: CLRegion?,
                        withError error: Error) {
        logger.error("❌ Region monitoring failed for \(region?.identifier ?? "unknown"): \(error)")
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false

        // Stop location updates
        manager.stopMonitoringSignificantLocationChanges()

        // Do NOT deregister regions here. startMonitoring's rebuild loop already retains
        // valid regions and stops stale ones. Deregistering then re-registering causes iOS
        // to fire didEnterRegion for any region it considers the user currently inside —
        // even if they're far away — triggering spurious sheet presentations.
        allGeofences.removeAll()
        activeGeofences.removeAll()
        monitoredGeofenceIds.removeAll()
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

            // Request current state to handle case where user is already inside
            manager.requestState(for: region)
        }

        // Update tracked state
        monitoredGeofenceIds = nearestIds
        lastRegionUpdateLocation = location
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

            let isNew = !monitoredGeofenceIds.contains(config.id)
            manager.startMonitoring(for: region)
            activeGeofences[config.id] = config
            monitoredGeofenceIds.insert(config.id)
            logger.debug("Fallback registered: \(config.name)")

            // Only request state for newly added regions — not existing ones that may have
            // a pending didEnterRegion event queued, which requestState would race against.
            if isNew {
                manager.requestState(for: region)
            }
        }
    }

    private func notify(_ configuration: GeofenceConfiguration) {
        // Check cooldown first — applies to both sheets and OS notifications.
        // Prevents repeated presentations when GPS oscillates around the boundary.
        if let lastTime = lastNotificationTime[configuration.id] {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < notificationCooldown {
                logger.info("⏱️ Skipping notification (cooldown) - sent \(Int(elapsed))s ago")
                return
            }
        }

        lastNotificationTime[configuration.id] = Date()
        persistLastNotificationTime()

        let appState = UIApplication.shared.applicationState
        if appState == .active {
            logger.info("📱 App is active - showing sheet directly for: \(configuration.name)")
            NavigationCoordinator.shared.showSpotDetail(spotId: configuration.id)
            return
        }

        sendNotification(for: configuration)
    }

    private func sendNotification(for configuration: GeofenceConfiguration) {
        logger.info("🔔 Sending notification for: \(configuration.name)")

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.title = configuration.name
        if !configuration.group.isEmpty { content.subtitle = configuration.group }
        content.body = "You're nearby. Open Spots to learn more."
        content.userInfo = [
            "geofenceId": configuration.id,
            "geofenceName": configuration.name,
            "geofenceGroup": configuration.group,
            "geofenceCity": configuration.city,
            "geofenceCountry": configuration.country,
            "destinationLat": configuration.latitude,
            "destinationLon": configuration.longitude,
            "isGrouped": false
        ]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            guard let self else { return }
            if let error {
                self.logger.error("❌ Notification failed: \(error.localizedDescription)")
            } else {
                self.logger.info("✅ Notification delivered for: \(configuration.name)")
            }
        }
    }
}
