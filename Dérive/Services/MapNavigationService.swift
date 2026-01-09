//
//  MapNavigationService.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-28.
//

import UIKit
import os.log

final class MapNavigationService {

    private let logger = Logger(subsystem: "com.derive.app", category: "MapNavigationService")

    static let shared = MapNavigationService()

    private init() {}

    // MARK: - Public Methods

    func openAppleMaps(latitude: Double, longitude: Double) {
        // Apple Maps URL with walking directions
        let urlString = "https://maps.apple.com/?saddr=Current+Location&daddr=\(latitude),\(longitude)&dirflg=w"

        guard let url = URL(string: urlString) else {
            logger.error("Invalid Apple Maps URL")
            return
        }

        UIApplication.shared.open(url) { success in
            if success {
                self.logger.info("Opened Apple Maps successfully")
            } else {
                self.logger.error("Failed to open Apple Maps")
            }
        }
    }

    func openGoogleMaps(latitude: Double, longitude: Double) {
        // Try Google Maps app first
        let appURLString = "comgooglemaps://?daddr=\(latitude),\(longitude)&directionsmode=walking"

        if let appURL = URL(string: appURLString),
           UIApplication.shared.canOpenURL(appURL) {
            // Google Maps app is installed
            UIApplication.shared.open(appURL) { success in
                if success {
                    self.logger.info("Opened Google Maps app successfully")
                } else {
                    self.logger.error("Failed to open Google Maps app")
                }
            }
        } else {
            // Fallback to web version
            let webURLString = "https://www.google.com/maps/dir/?api=1&destination=\(latitude),\(longitude)&travelmode=walking"

            guard let webURL = URL(string: webURLString) else {
                logger.error("Invalid Google Maps web URL")
                return
            }

            UIApplication.shared.open(webURL) { success in
                if success {
                    self.logger.info("Opened Google Maps web version successfully")
                } else {
                    self.logger.error("Failed to open Google Maps web version")
                }
            }
        }
    }

    func openMapApp(_ mapApp: MapApp, latitude: Double, longitude: Double) {
        switch mapApp {
        case .appleMaps:
            openAppleMaps(latitude: latitude, longitude: longitude)
        case .googleMaps:
            openGoogleMaps(latitude: latitude, longitude: longitude)
        }
    }
}
