//
//  TabItem.swift
//  Purpose: Tab definitions for native iOS TabView
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-30.
//

import SwiftUI

// MARK: - Tab Item

/// Tab definitions for native iOS TabView
enum TabItem: Int, CaseIterable, Identifiable {
    case nearbySpots
    case curatedLists
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .nearbySpots: return "Nearby Spots"
        case .curatedLists: return "Curated Lists"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .nearbySpots: return "mappin.and.ellipse"
        case .curatedLists: return "list.bullet"
        case .settings: return "gearshape"
        }
    }
}
