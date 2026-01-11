//
//  GeofenceLoaderService.swift
//  Dérive
//
//  Purpose: Load and parse geofences from cached city data
//

import Foundation
import os.log

enum GeofenceLoaderError: Error, LocalizedError {
    case noCitySelected
    case cityNotDownloaded(String)
    case invalidJSON(Error)
    case decodingFailed(Error)
    case noGeofences

    var errorDescription: String? {
        switch self {
        case .noCitySelected:
            return "No city has been selected. Please select a city first."
        case .cityNotDownloaded(let cityId):
            return "City '\(cityId)' has not been downloaded yet."
        case .invalidJSON(let error):
            return "Invalid JSON format: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode geofences: \(error.localizedDescription)"
        case .noGeofences:
            return "No geofences found in the selected city"
        }
    }
}

final class GeofenceLoaderService {

    private let logger = Logger(subsystem: "com.derive.app", category: "GeofenceLoader")

    static let shared = GeofenceLoaderService()

    private init() {}

    // MARK: - Public Methods

    /// Loads geofences for the currently selected city
    /// - Returns: Array of GeofenceConfiguration objects
    /// - Throws: GeofenceLoaderError if no city selected or loading fails
    func loadGeofences() throws -> [GeofenceConfiguration] {
        logger.info("Loading geofences for selected city...")

        // Use CityService to load geofences
        let geofences = try CityService.shared.loadSelectedCityGeofences()

        logger.info("Loaded \(geofences.count) geofences")

        // Validate we have at least one geofence
        guard !geofences.isEmpty else {
            logger.warning("No geofences found")
            throw GeofenceLoaderError.noGeofences
        }

        // Log info about monitoring
        if geofences.count > 20 {
            logger.info("Found \(geofences.count) geofences. GeofenceManager will monitor the nearest 20.")
        }

        return geofences
    }

    /// Check if geofences can be loaded (city is selected and downloaded)
    func canLoadGeofences() -> Bool {
        return CityService.shared.hasSelectedCity()
    }
}
