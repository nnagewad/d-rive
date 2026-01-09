//
//  SettingsService.swift
//  Dérive
//

import Foundation
import Combine
import os.log

enum MapApp: String, CaseIterable, Identifiable {
    case appleMaps = "apple_maps"
    case googleMaps = "google_maps"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appleMaps: return "Apple Maps"
        case .googleMaps: return "Google Maps"
        }
    }

    var iconName: String {
        switch self {
        case .appleMaps: return "map.fill"
        case .googleMaps: return "globe"
        }
    }
}

@MainActor
final class SettingsService: ObservableObject {
    static let shared = SettingsService()

    private let logger = Logger(subsystem: "com.derive.app", category: "SettingsService")
    private let defaultMapAppKey = "defaultMapApp"

    @Published var defaultMapApp: MapApp? {
        didSet {
            if let app = defaultMapApp {
                UserDefaults.standard.set(app.rawValue, forKey: defaultMapAppKey)
                logger.info("Default map app set to: \(app.displayName)")
            } else {
                UserDefaults.standard.removeObject(forKey: defaultMapAppKey)
                logger.info("Default map app cleared")
            }
        }
    }

    private init() {
        if let savedValue = UserDefaults.standard.string(forKey: defaultMapAppKey),
           let mapApp = MapApp(rawValue: savedValue) {
            self.defaultMapApp = mapApp
            logger.info("Loaded default map app: \(mapApp.displayName)")
        } else {
            self.defaultMapApp = nil
            logger.info("No default map app set")
        }
    }
}
