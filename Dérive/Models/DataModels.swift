//
//  DataModels.swift
//  Dérive
//
//  Purpose: SwiftData models for the app's core data
//

import Foundation
import SwiftData

// MARK: - City

@Model
final class CityData {
    @Attribute(.unique) var id: String
    var name: String
    var country: String

    @Relationship(deleteRule: .cascade, inverse: \CuratedListData.city)
    var lists: [CuratedListData] = []

    init(id: String = UUID().uuidString, name: String, country: String) {
        self.id = id
        self.name = name
        self.country = country
    }
}

// MARK: - Curator

@Model
final class CuratorData {
    @Attribute(.unique) var id: String
    var name: String
    var bio: String
    var instagramHandle: String?

    @Relationship(deleteRule: .nullify, inverse: \CuratedListData.curator)
    var lists: [CuratedListData] = []

    init(id: String = UUID().uuidString, name: String, bio: String, instagramHandle: String? = nil) {
        self.id = id
        self.name = name
        self.bio = bio
        self.instagramHandle = instagramHandle
    }
}

// MARK: - Curated List

@Model
final class CuratedListData {
    @Attribute(.unique) var id: String
    var name: String
    var listDescription: String
    var isDownloaded: Bool
    var version: Int
    var lastUpdated: Date
    var notifyWhenNearby: Bool

    var city: CityData?
    var curator: CuratorData?

    @Relationship(deleteRule: .cascade, inverse: \SpotData.list)
    var spots: [SpotData] = []

    init(
        id: String = UUID().uuidString,
        name: String,
        listDescription: String = "",
        isDownloaded: Bool = false,
        version: Int = 1,
        lastUpdated: Date = .now,
        notifyWhenNearby: Bool = true
    ) {
        self.id = id
        self.name = name
        self.listDescription = listDescription
        self.isDownloaded = isDownloaded
        self.version = version
        self.lastUpdated = lastUpdated
        self.notifyWhenNearby = notifyWhenNearby
    }
}

// MARK: - Spot (contains geofence coordinates)

@Model
final class SpotData {
    @Attribute(.unique) var id: String
    var name: String
    var category: String
    var spotDescription: String

    // Geofence coordinates
    var latitude: Double
    var longitude: Double
    var radius: Double

    // Optional metadata
    var instagramHandle: String?
    var websiteURL: String?
    var address: String?

    var list: CuratedListData?

    /// Computed: Should this spot trigger geofence notifications?
    var isGeofenceActive: Bool {
        guard let list = list else { return false }
        return list.isDownloaded && list.notifyWhenNearby
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        category: String = "",
        spotDescription: String = "",
        latitude: Double,
        longitude: Double,
        radius: Double = 100.0,
        instagramHandle: String? = nil,
        websiteURL: String? = nil,
        address: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.spotDescription = spotDescription
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.instagramHandle = instagramHandle
        self.websiteURL = websiteURL
        self.address = address
    }
}

// MARK: - Convenience Extensions

extension SpotData {
    /// Convert to GeofenceConfiguration for the GeofenceManager
    func toGeofenceConfiguration() -> GeofenceConfiguration {
        GeofenceConfiguration(
            id: id,
            name: name,
            group: category,
            city: list?.city?.name ?? "",
            country: list?.city?.country ?? "",
            source: list?.name ?? "",
            latitude: latitude,
            longitude: longitude,
            radius: radius
        )
    }
}

extension CuratedListData {
    /// Get all spots as geofence configurations
    var geofenceConfigurations: [GeofenceConfiguration] {
        spots.map { $0.toGeofenceConfiguration() }
    }
}
