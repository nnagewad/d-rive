//
//  NavigationCoordinator.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-30.
//

import SwiftUI
import Combine
import os.log

// MARK: - MapDestination

struct MapDestination: Hashable, Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let name: String
    let group: String
    let city: String
    let country: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MapDestination, rhs: MapDestination) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - NavigationCoordinator

@MainActor
final class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()

    private let logger = Logger(subsystem: "com.derive.app", category: "NavigationCoordinator")

    @Published var navigationPath = NavigationPath()
    @Published var currentDestination: MapDestination?

    private init() {
        logger.info("🗺️ NavigationCoordinator initialized")
    }

    func navigateToMapSelection(latitude: Double, longitude: Double, name: String, group: String, city: String, country: String) {
        logger.info("🗺️ Navigating to map selection for: \(name)")

        let destination = MapDestination(
            latitude: latitude,
            longitude: longitude,
            name: name,
            group: group,
            city: city,
            country: country
        )
        currentDestination = destination
        navigationPath.append(destination)

        logger.info("✅ Navigation triggered - path count: \(self.navigationPath.count)")
    }

    func clearNavigation() {
        logger.info("🗺️ Clearing navigation")
        navigationPath = NavigationPath()
        currentDestination = nil
    }

    func navigateToCityList() {
        logger.info("🗺️ Navigating to city list")
        // CityListView is the root, so clear the navigation path to return there
        navigationPath = NavigationPath()
        currentDestination = nil
    }
}
