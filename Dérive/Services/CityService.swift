//
//  CityService.swift
//  Dérive
//
//  Purpose: Fetch and cache city geofence data from remote GitHub repository
//

import Foundation
import Combine
import os.log

enum CityServiceError: Error, LocalizedError {
    case networkError(Error)
    case invalidResponse
    case decodingFailed(Error)
    case noCitySelected
    case cityNotDownloaded(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .noCitySelected:
            return "No city has been selected"
        case .cityNotDownloaded(let cityId):
            return "City '\(cityId)' has not been downloaded"
        }
    }
}

final class CityService: ObservableObject {

    private let logger = Logger(subsystem: "com.derive.app", category: "CityService")

    static let shared = CityService()

    // GitHub raw content base URL
    private let baseURL = "https://raw.githubusercontent.com/nnagewad/derive-cities/main"

    // Published properties for UI
    @Published var manifest: CityManifest?
    @Published var isLoadingManifest = false
    @Published var downloadingCities: Set<String> = []

    // UserDefaults keys
    private let selectedCityKey = "selectedCityId"
    private let manifestVersionKey = "manifestVersion"

    private init() {}

    // MARK: - Directory Management

    /// Documents directory for caching
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Directory for cached city files
    private var citiesDirectory: URL {
        documentsDirectory.appendingPathComponent("cities", isDirectory: true)
    }

    /// Cached manifest file path
    private var cachedManifestURL: URL {
        documentsDirectory.appendingPathComponent("manifest.json")
    }

    /// Ensures the cities directory exists
    private func ensureCitiesDirectoryExists() throws {
        if !FileManager.default.fileExists(atPath: citiesDirectory.path) {
            try FileManager.default.createDirectory(at: citiesDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Selected City

    /// Get the currently selected city ID
    var selectedCityId: String? {
        get { UserDefaults.standard.string(forKey: selectedCityKey) }
        set { UserDefaults.standard.set(newValue, forKey: selectedCityKey) }
    }

    /// Check if a city is downloaded
    func isCityDownloaded(_ cityId: String) -> Bool {
        let cityURL = citiesDirectory.appendingPathComponent("\(cityId).json")
        return FileManager.default.fileExists(atPath: cityURL.path)
    }

    /// Check if a city has an update available
    func cityNeedsUpdate(_ city: City) -> Bool {
        guard let cachedVersion = getCachedCityVersion(city.id) else {
            return true // Not downloaded yet
        }
        return cachedVersion != city.version
    }

    /// Get cached city version
    private func getCachedCityVersion(_ cityId: String) -> String? {
        let versionKey = "cityVersion_\(cityId)"
        return UserDefaults.standard.string(forKey: versionKey)
    }

    /// Set cached city version
    private func setCachedCityVersion(_ cityId: String, version: String) {
        let versionKey = "cityVersion_\(cityId)"
        UserDefaults.standard.set(version, forKey: versionKey)
    }

    // MARK: - Manifest

    /// Fetch the city manifest from remote (or return cached if offline)
    @MainActor
    func fetchManifest() async throws -> CityManifest {
        isLoadingManifest = true
        defer { isLoadingManifest = false }

        let url = URL(string: "\(baseURL)/manifest.json")!

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw CityServiceError.invalidResponse
            }

            let decoder = JSONDecoder()
            let manifest = try decoder.decode(CityManifest.self, from: data)

            // Cache the manifest
            try data.write(to: cachedManifestURL)
            logger.info("Fetched and cached manifest with \(manifest.cities.count) cities")

            self.manifest = manifest
            return manifest

        } catch {
            logger.warning("Failed to fetch remote manifest: \(error.localizedDescription)")

            // Try to load cached manifest
            if let cachedManifest = loadCachedManifest() {
                logger.info("Using cached manifest")
                self.manifest = cachedManifest
                return cachedManifest
            }

            throw CityServiceError.networkError(error)
        }
    }

    /// Load cached manifest from disk
    func loadCachedManifest() -> CityManifest? {
        guard FileManager.default.fileExists(atPath: cachedManifestURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: cachedManifestURL)
            let manifest = try JSONDecoder().decode(CityManifest.self, from: data)
            return manifest
        } catch {
            logger.error("Failed to load cached manifest: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - City Download

    /// Download a city's geofence data
    @MainActor
    func downloadCity(_ city: City) async throws {
        downloadingCities.insert(city.id)
        defer { downloadingCities.remove(city.id) }

        let url = URL(string: "\(baseURL)/\(city.fileName)")!

        do {
            try ensureCitiesDirectoryExists()

            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw CityServiceError.invalidResponse
            }

            // Validate the data is valid JSON
            _ = try JSONDecoder().decode(CityGeofenceData.self, from: data)

            // Save to disk
            let cityURL = citiesDirectory.appendingPathComponent("\(city.id).json")
            try data.write(to: cityURL)

            // Save version
            setCachedCityVersion(city.id, version: city.version)

            logger.info("Downloaded city: \(city.name) (v\(city.version))")

        } catch {
            logger.error("Failed to download city \(city.name): \(error.localizedDescription)")
            throw CityServiceError.networkError(error)
        }
    }

    /// Select a city (must be downloaded first)
    func selectCity(_ cityId: String) throws {
        guard isCityDownloaded(cityId) else {
            throw CityServiceError.cityNotDownloaded(cityId)
        }
        selectedCityId = cityId
        logger.info("Selected city: \(cityId)")
    }

    // MARK: - Load City Data

    /// Load geofence data for the selected city
    func loadSelectedCityGeofences() throws -> [GeofenceConfiguration] {
        guard let cityId = selectedCityId else {
            throw CityServiceError.noCitySelected
        }
        return try loadCityGeofences(cityId)
    }

    /// Load geofence data for a specific city
    func loadCityGeofences(_ cityId: String) throws -> [GeofenceConfiguration] {
        let cityURL = citiesDirectory.appendingPathComponent("\(cityId).json")

        guard FileManager.default.fileExists(atPath: cityURL.path) else {
            throw CityServiceError.cityNotDownloaded(cityId)
        }

        let data = try Data(contentsOf: cityURL)
        let cityData = try JSONDecoder().decode(CityGeofenceData.self, from: data)

        // Convert to GeofenceConfiguration
        let configurations = cityData.geofences.map { geofence in
            GeofenceConfiguration(
                id: geofence.id,
                name: geofence.name,
                group: geofence.group,
                city: cityData.city,
                country: "", // Not stored in city file
                source: "Remote",
                latitude: geofence.latitude,
                longitude: geofence.longitude,
                radius: cityData.defaultRadius
            )
        }

        logger.info("Loaded \(configurations.count) geofences for city: \(cityId)")
        return configurations
    }

    /// Check if any city is downloaded and selected
    func hasSelectedCity() -> Bool {
        guard let cityId = selectedCityId else { return false }
        return isCityDownloaded(cityId)
    }

    // MARK: - Delete City

    /// Delete a downloaded city
    func deleteCity(_ cityId: String) throws {
        let cityURL = citiesDirectory.appendingPathComponent("\(cityId).json")

        if FileManager.default.fileExists(atPath: cityURL.path) {
            try FileManager.default.removeItem(at: cityURL)
        }

        // Clear version
        let versionKey = "cityVersion_\(cityId)"
        UserDefaults.standard.removeObject(forKey: versionKey)

        // Clear selection if this was the selected city
        if selectedCityId == cityId {
            selectedCityId = nil
        }

        logger.info("Deleted city: \(cityId)")
    }
}
