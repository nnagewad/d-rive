//
//  NavigationCoordinator.swift
//  Purpose: Coordinates app navigation and handles deep linking from notifications
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-30.
//

import SwiftUI
import Combine
import os.log

// MARK: - NavigationCoordinator

@MainActor
final class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()

    private let logger = Logger(subsystem: "com.derive.app", category: "NavigationCoordinator")

    @Published var navigationPath = NavigationPath()
    @Published var selectedSpotId: String?

    private init() {
        logger.info("🗺️ NavigationCoordinator initialized")
    }

    func showSpotDetail(spotId: String) {
        logger.info("🗺️ Showing spot detail for ID: \(spotId)")
        selectedSpotId = spotId
    }

    func dismissSpotDetail() {
        logger.info("🗺️ Dismissing spot detail")
        selectedSpotId = nil
    }

    func clearNavigation() {
        logger.info("🗺️ Clearing navigation")
        navigationPath = NavigationPath()
        selectedSpotId = nil
    }
}
