//
//  ListActionService.swift
//  Purpose: Orchestrates follow and stop actions for curated lists
//  Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2026-04-03.
//

import Foundation

@MainActor
final class ListActionService {

    static let shared = ListActionService()

    private init() {}

    /// Requests permissions, activates the list, and reloads geofences.
    /// Returns false if the caller should show a permission alert.
    func follow(_ list: CuratedListData) async -> Bool {
        guard await PermissionService.shared.requestPermissionsForListActivation() else {
            return false
        }
        DataService.shared.activateList(list)
        reloadGeofences()
        return true
    }

    func stop(_ list: CuratedListData) {
        list.notifyWhenNearby = false
        DataService.shared.save()
        reloadGeofences()
    }
}
