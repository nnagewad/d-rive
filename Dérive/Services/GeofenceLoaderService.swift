//
//  GeofenceLoaderService.swift
//  Dérive
//
//  Purpose: Load and parse geofences from JSON file in app bundle
//

import Foundation
import os.log

// Internal struct for decoding JSON (without radius field)
private struct GeofenceJSON: Codable {
    let id: String
    let name: String
    let group: String
    let city: String
    let country: String
    let source: String
    let latitude: Double
    let longitude: Double
}

private struct GeofenceBundleJSON: Codable {
    let version: String
    let defaultRadius: Double
    let geofences: [GeofenceJSON]
}

enum GeofenceLoaderError: Error, LocalizedError {
    case fileNotFound
    case invalidJSON(Error)
    case decodingFailed(Error)
    case noGeofences

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "geofences.json not found in app bundle"
        case .invalidJSON(let error):
            return "Invalid JSON format: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode geofences: \(error.localizedDescription)"
        case .noGeofences:
            return "No enabled geofences found in configuration"
        }
    }
}

final class GeofenceLoaderService {

    private let logger = Logger(subsystem: "com.derive.app", category: "GeofenceLoader")

    static let shared = GeofenceLoaderService()

    private init() {}

    // MARK: - Public Methods

    /// Loads geofences from app bundle JSON file
    /// - Returns: Array of enabled GeofenceConfiguration objects
    /// - Throws: GeofenceLoaderError if loading or parsing fails
    func loadGeofences() throws -> [GeofenceConfiguration] {
        logger.info("Loading geofences from bundle...")

        // 1. Locate JSON file in bundle
        guard let url = Bundle.main.url(forResource: "geofences", withExtension: "json") else {
            logger.error("geofences.json not found in bundle")
            throw GeofenceLoaderError.fileNotFound
        }

        // 2. Read file data
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            logger.error("Failed to read geofences.json: \(error)")
            throw GeofenceLoaderError.invalidJSON(error)
        }

        // 3. Decode JSON
        let bundle: GeofenceBundleJSON
        do {
            let decoder = JSONDecoder()
            bundle = try decoder.decode(GeofenceBundleJSON.self, from: data)
        } catch {
            logger.error("Failed to decode geofences.json: \(error)")
            throw GeofenceLoaderError.decodingFailed(error)
        }

        // 4. Apply defaultRadius to geofences
        let geofencesWithRadius = bundle.geofences.map { geofence in
            GeofenceConfiguration(
                id: geofence.id,
                name: geofence.name,
                group: geofence.group,
                city: geofence.city,
                country: geofence.country,
                source: geofence.source,
                latitude: geofence.latitude,
                longitude: geofence.longitude,
                radius: bundle.defaultRadius
            )
        }

        logger.info("Loaded \(geofencesWithRadius.count) geofences")

        // 5. Validate we have at least one geofence
        guard !geofencesWithRadius.isEmpty else {
            logger.warning("No geofences found in JSON")
            throw GeofenceLoaderError.noGeofences
        }

        // 6. Log if exceeding iOS 20-geofence limit (GeofenceManager handles dynamic selection)
        if geofencesWithRadius.count > 20 {
            logger.info("Found \(geofencesWithRadius.count) geofences. GeofenceManager will monitor the nearest 20.")
        }

        // 7. Return all geofences (GeofenceManager selects nearest 20 to monitor)
        return geofencesWithRadius
    }
}
