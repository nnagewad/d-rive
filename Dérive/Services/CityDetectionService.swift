//
//  CityDetectionService.swift
//  Dérive
//
//  Purpose: Detect user's current city via reverse geocoding and handle auto-switching
//

import Foundation
import CoreLocation
import UserNotifications
import os.log

extension Notification.Name {
    static let citySwitchedAutomatically = Notification.Name("citySwitchedAutomatically")
}

@MainActor
final class CityDetectionService {

    static let shared = CityDetectionService()

    private let logger = Logger(subsystem: "com.derive.app", category: "CityDetection")
    private let geocoder = CLGeocoder()

    // Track last detected city to avoid redundant processing
    private var lastDetectedCityName: String?
    private var lastDetectedCountryName: String?
    private var lastGeocodingLocation: CLLocation?

    // Minimum distance before re-geocoding (meters)
    private let geocodingDistanceThreshold: Double = 5000 // 5km

    // Cooldown between geocoding attempts
    private var lastGeocodingTime: Date?
    private let geocodingCooldown: TimeInterval = 300 // 5 minutes

    private init() {}

    /// Check if user has moved to a different city
    /// Called from GeofenceManager on significant location changes
    func checkCity(for location: CLLocation) {
        // Check cooldown
        if let lastTime = lastGeocodingTime,
           Date().timeIntervalSince(lastTime) < geocodingCooldown {
            logger.debug("Skipping geocoding - cooldown active")
            return
        }

        // Check distance threshold
        if let lastLocation = lastGeocodingLocation,
           location.distance(from: lastLocation) < geocodingDistanceThreshold {
            logger.debug("Skipping geocoding - insufficient movement")
            return
        }

        performGeocodingCheck(for: location)
    }

    private func performGeocodingCheck(for location: CLLocation) {
        lastGeocodingTime = Date()
        lastGeocodingLocation = location

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if let error = error {
                    self.logger.warning("Geocoding failed: \(error.localizedDescription)")
                    return
                }

                guard let placemark = placemarks?.first,
                      let cityName = placemark.locality,
                      let countryName = placemark.country else {
                    self.logger.debug("No city found in placemark")
                    return
                }

                self.handleDetectedCity(cityName: cityName, countryName: countryName)
            }
        }
    }

    private func handleDetectedCity(cityName: String, countryName: String) {
        // Check if this is a new city
        if cityName == lastDetectedCityName && countryName == lastDetectedCountryName {
            logger.debug("Still in same city: \(cityName)")
            return
        }

        logger.info("Detected city change: \(cityName), \(countryName)")
        lastDetectedCityName = cityName
        lastDetectedCountryName = countryName

        // Try to find matching city in manifest
        attemptCitySwitch(cityName: cityName, countryName: countryName)
    }

    private func attemptCitySwitch(cityName: String, countryName: String) {
        guard let manifest = CityService.shared.manifest else {
            // Try loading cached manifest
            guard let cachedManifest = CityService.shared.loadCachedManifest() else {
                logger.warning("No manifest available for city matching")
                return
            }
            matchCity(cityName: cityName, countryName: countryName, in: cachedManifest)
            return
        }

        matchCity(cityName: cityName, countryName: countryName, in: manifest)
    }

    private func matchCity(cityName: String, countryName: String, in manifest: CityManifest) {
        // Find matching city (case-insensitive)
        let matchingCity = manifest.cities.first { city in
            city.name.localizedCaseInsensitiveCompare(cityName) == .orderedSame &&
            city.country.localizedCaseInsensitiveCompare(countryName) == .orderedSame
        }

        guard let city = matchingCity else {
            logger.info("City '\(cityName)' not in manifest - no notification")
            return
        }

        // Check if city is downloaded
        guard CityService.shared.isCityDownloaded(city.id) else {
            logger.info("City '\(city.name)' not downloaded")
            sendCityUnavailableNotification(cityName: city.name, countryName: city.country)
            return
        }

        // Check if already selected
        guard CityService.shared.selectedCityId != city.id else {
            logger.debug("City '\(city.name)' already selected")
            return
        }

        // Send prompt notification instead of auto-switching
        sendCitySwitchPrompt(for: city)
    }

    private func sendCitySwitchPrompt(for city: City) {
        logger.info("Sending city switch prompt for: \(city.name)")

        let content = UNMutableNotificationContent()
        content.title = "You're in \(city.name)"
        content.sound = .default
        content.userInfo = [
            "cityId": city.id,
            "cityName": city.name,
            "action": "switchCity"
        ]

        let request = UNNotificationRequest(
            identifier: "city-switch-\(city.id)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to send city switch prompt: \(error.localizedDescription)")
            }
        }
    }

    /// Called when user taps the city switch notification
    func switchToCity(cityId: String) {
        guard CityService.shared.isCityDownloaded(cityId) else {
            logger.error("Cannot switch - city '\(cityId)' not downloaded")
            return
        }

        do {
            try CityService.shared.selectCity(cityId)
            logger.info("Switched to city: \(cityId)")

            // Post notification for AppDelegate to restart monitoring
            NotificationCenter.default.post(
                name: .citySwitchedAutomatically,
                object: nil,
                userInfo: ["cityId": cityId]
            )

        } catch {
            logger.error("Failed to switch city: \(error.localizedDescription)")
        }
    }

    private func sendCityUnavailableNotification(cityName: String, countryName: String) {
        let content = UNMutableNotificationContent()
        content.title = "You're in \(cityName)"
        content.body = "See what lists are available to download"
        content.sound = .default
        content.userInfo = [
            "cityName": cityName,
            "action": "openCityList"
        ]

        let request = UNNotificationRequest(
            identifier: "city-unavailable-\(cityName.lowercased().replacingOccurrences(of: " ", with: "-"))",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to send city notification: \(error.localizedDescription)")
            }
        }
    }
}
