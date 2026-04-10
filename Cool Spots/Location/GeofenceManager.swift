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

    // Track which geofences we're currently inside
    private var insideGeofences: Set<String> = []

    // Track initial state determinations to send notifications
    private var pendingInitialStates: Set<String> = []

    // Track last notification time to prevent duplicates (region + GPS triggering together)
    private var lastNotificationTime: [String: Date] = [:]
    private let notificationCooldown: TimeInterval = 60  // 60 seconds between notifications

    // Snooze: suppress notifications for a spot after its sheet is dismissed
    private var snoozedUntil: [String: Date] = [:]
    private let snoozeKey = "GeofenceManager.snoozedUntil"
    private let snoozeDuration: TimeInterval = 3600  // 1 hour

    // Batch nearby notifications into one when multiple geofences trigger within this window
    private var pendingNotifications: [GeofenceConfiguration] = []
    private var notificationBatchTask: Task<Void, Never>?
    private let notificationBatchWindow: TimeInterval = 3

    override init() {
        super.init()
        manager.delegate = self
        if let data = UserDefaults.standard.data(forKey: snoozeKey),
           let saved = try? JSONDecoder().decode([String: Date].self, from: data) {
            snoozedUntil = saved
        }
    }

    func snooze(spotId: String) {
        snoozedUntil[spotId] = Date().addingTimeInterval(snoozeDuration)
        if let data = try? JSONEncoder().encode(snoozedUntil) {
            UserDefaults.standard.set(data, forKey: snoozeKey)
        }
        logger.info("💤 Snoozed \(spotId) for \(Int(self.snoozeDuration / 60)) minutes")
    }

    private func isSnoozed(_ spotId: String) -> Bool {
        guard let expiry = snoozedUntil[spotId] else { return false }
        return Date() < expiry
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
            let isInside = distance <= config.radius

            logger.debug("Distance to \(config.name): \(Int(distance))m (radius: \(Int(config.radius))m)")

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

        // Cross-check with GPS if available. If not (background/terminated), trust iOS.
        if let gpsLocation = verifiedGPSLocation {
            let center = CLLocationCoordinate2D(latitude: config.latitude, longitude: config.longitude)
            let gpsDistance = gpsLocation.distance(from: center)
            guard gpsDistance <= config.radius else {
                logger.info("🌍 REGION ENTER but GPS says \(Int(gpsDistance))m away, ignoring")
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
            // User is already inside this region when we started monitoring
            // This handles the case where regions are re-registered while user is inside
            let wasInside = insideGeofences.contains(region.identifier)
            insideGeofences.insert(region.identifier)

            if !wasInside {
                // didDetermineState fires on startup/foreground return and uses iOS's
                // coarse positioning (cell towers/WiFi) which can be inaccurate by hundreds
                // of metres. Always require a verified GPS fix. If none yet, defer — the
                // GPS path in handleLocationUpdate will confirm entry once a fix arrives.
                guard let gpsLocation = verifiedGPSLocation else {
                    logger.info("🌍 REGION STATE INSIDE but no verified GPS, deferring: \(config.name)")
                    insideGeofences.remove(region.identifier)
                    return
                }
                let center = CLLocationCoordinate2D(latitude: config.latitude, longitude: config.longitude)
                let gpsDistance = gpsLocation.distance(from: center)
                guard gpsDistance <= config.radius else {
                    logger.info("🌍 REGION STATE INSIDE but GPS says \(Int(gpsDistance))m away, ignoring: \(config.name)")
                    insideGeofences.remove(region.identifier)
                    return
                }
                logger.info("🌍 REGION STATE INSIDE (was outside): \(config.name)")
                notify(config)
            } else {
                logger.debug("🌍 REGION STATE INSIDE (already tracked): \(config.name)")
            }

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

        // Stop region monitoring
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }

        // Cancel any pending batch notification
        notificationBatchTask?.cancel()
        notificationBatchTask = nil
        pendingNotifications.removeAll()

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

            manager.startMonitoring(for: region)
            activeGeofences[config.id] = config
            monitoredGeofenceIds.insert(config.id)
            logger.debug("Fallback registered: \(config.name)")

            // Request current state to handle case where user is already inside
            manager.requestState(for: region)
        }
    }

    private func notify(_ configuration: GeofenceConfiguration) {
        // Check snooze first
        if isSnoozed(configuration.id) {
            logger.info("💤 Skipping notification (snoozed): \(configuration.name)")
            return
        }

        // Check cooldown to prevent duplicate notifications for the same spot
        if let lastTime = lastNotificationTime[configuration.id] {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < notificationCooldown {
                logger.info("⏱️ Skipping notification (cooldown) - sent \(Int(elapsed))s ago")
                return
            }
        }

        lastNotificationTime[configuration.id] = Date()

        // If app is active, show sheet directly instead of notification
        let appState = UIApplication.shared.applicationState
        if appState == .active {
            logger.info("📱 App is active - showing sheet directly for: \(configuration.name)")
            NavigationCoordinator.shared.showSpotDetail(spotId: configuration.id)
            return
        }

        pendingNotifications.append(configuration)
        notificationBatchTask?.cancel()
        notificationBatchTask = Task {
            if appState == .background {
                // Extend background execution so iOS doesn't suspend us mid-batch
                let bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                defer { UIApplication.shared.endBackgroundTask(bgTask) }
                try? await Task.sleep(nanoseconds: UInt64(notificationBatchWindow * 1_000_000_000))
            } else {
                try? await Task.sleep(nanoseconds: UInt64(notificationBatchWindow * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            self.flushPendingNotifications()
        }
    }

    private func flushPendingNotifications() {
        let batch = pendingNotifications
        pendingNotifications.removeAll()

        guard let first = batch.first else { return }

        let isGrouped = batch.count > 1
        let body: String
        if isGrouped {
            body = "You're near \(first.name) and \(batch.count - 1) other spot\(batch.count - 1 == 1 ? "" : "s")"
        } else {
            body = "You're close to \(first.name)!"
        }

        logger.info("🔔 Sending notification (batch of \(batch.count)): \(body)")

        let content = UNMutableNotificationContent()
        content.title = "Cool Spots"
        content.body = body
        content.sound = .default
        content.userInfo = [
            "geofenceId": first.id,
            "geofenceName": first.name,
            "geofenceGroup": first.group,
            "geofenceCity": first.city,
            "geofenceCountry": first.country,
            "destinationLat": first.latitude,
            "destinationLon": first.longitude,
            "isGrouped": isGrouped
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let error = error {
                    self.logger.error("❌ Notification failed: \(error.localizedDescription)")
                } else {
                    self.logger.info("✅ Notification sent for batch of \(batch.count)")
                }
            }
        }
    }
}
