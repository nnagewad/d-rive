//
//  GeofenceLoaderService.swift
//  Dérive
//
//  Purpose: Load geofences from SwiftData (spots in downloaded lists)
//

import Foundation
import os.log

enum GeofenceLoaderError: Error, LocalizedError {
    case noDownloadedLists
    case noActiveSpots
    case dataServiceNotConfigured

    var errorDescription: String? {
        switch self {
        case .noDownloadedLists:
            return "No curated lists have been downloaded yet."
        case .noActiveSpots:
            return "No spots are active for geofencing."
        case .dataServiceNotConfigured:
            return "DataService has not been configured yet."
        }
    }
}

@MainActor
final class GeofenceLoaderService {

    private let logger = Logger(subsystem: "com.derive.app", category: "GeofenceLoader")

    static let shared = GeofenceLoaderService()

    private init() {}

    // MARK: - Public Methods

    /// Loads geofences from SwiftData (spots in downloaded lists with notifications enabled)
    /// - Returns: Array of GeofenceConfiguration objects
    /// - Throws: GeofenceLoaderError if no active spots
    func loadGeofences() throws -> [GeofenceConfiguration] {
        logger.info("Loading geofences from SwiftData...")

        let configurations = DataService.shared.getGeofenceConfigurations()

        guard !configurations.isEmpty else {
            logger.warning("No active geofences found")
            throw GeofenceLoaderError.noActiveSpots
        }

        logger.info("Loaded \(configurations.count) geofences from SwiftData")

        if configurations.count > 20 {
            logger.info("Found \(configurations.count) geofences. GeofenceManager will monitor the nearest 20.")
        }

        return configurations
    }

    /// Check if geofences can be loaded (has downloaded lists with notifications enabled)
    func canLoadGeofences() -> Bool {
        return !DataService.shared.getNotificationGeofenceSpots().isEmpty
    }

    /// Reload geofences and restart monitoring
    func reloadAndRestartMonitoring() {
        logger.info("Reloading geofences and restarting monitoring...")

        // Stop existing monitoring
        GeofenceManager.shared.stopMonitoring()

        // Load fresh and start if we have geofences
        do {
            let geofences = try loadGeofences()
            GeofenceManager.shared.startMonitoring(configurations: geofences)
            logger.info("Restarted monitoring with \(geofences.count) geofences")
        } catch {
            logger.info("No geofences to monitor: \(error.localizedDescription)")
        }
    }
}
