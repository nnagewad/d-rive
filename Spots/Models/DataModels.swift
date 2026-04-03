//
//  DataModels.swift
//  Purpose: SwiftData models for the app's core data
//  Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2026-01-19.
//

import Foundation
import SwiftData

// MARK: - Country

@Model
final class CountryData {
    @Attribute(.unique) var id: String
    var name: String
    var version: Int

    @Relationship(deleteRule: .cascade, inverse: \CityData.countryData)
    var cities: [CityData] = []

    init(id: String = UUID().uuidString, name: String, version: Int = 1) {
        self.id = id
        self.name = name
        self.version = version
    }
}

// MARK: - City

@Model
final class CityData {
    @Attribute(.unique) var id: String
    var name: String
    var version: Int

    var countryData: CountryData?

    @Relationship(deleteRule: .cascade, inverse: \CuratedListData.city)
    var lists: [CuratedListData] = []

    /// Backwards compatible: returns country name string
    var country: String {
        countryData?.name ?? ""
    }

    init(id: String = UUID().uuidString, name: String, version: Int = 1, countryData: CountryData? = nil) {
        self.id = id
        self.name = name
        self.version = version
        self.countryData = countryData
    }
}

// MARK: - Spot Category

@Model
final class SpotCategoryData {
    @Attribute(.unique) var id: String
    var name: String
    var version: Int

    @Relationship(deleteRule: .nullify, inverse: \SpotData.categoryData)
    var spots: [SpotData] = []

    init(id: String = UUID().uuidString, name: String, version: Int = 1) {
        self.id = id
        self.name = name
        self.version = version
    }
}

// MARK: - Curator

@Model
final class CuratorData {
    @Attribute(.unique) var id: String
    var name: String
    var bio: String
    var imageUrl: String?
    var instagramHandle: String?
    var websiteURL: String?
    var version: Int

    @Relationship(deleteRule: .nullify, inverse: \CuratedListData.curator)
    var lists: [CuratedListData] = []

    init(
        id: String = UUID().uuidString,
        name: String,
        bio: String,
        imageUrl: String? = nil,
        instagramHandle: String? = nil,
        websiteURL: String? = nil,
        version: Int = 1
    ) {
        self.id = id
        self.name = name
        self.bio = bio
        self.imageUrl = imageUrl
        self.instagramHandle = instagramHandle
        self.websiteURL = websiteURL
        self.version = version
    }
}

// MARK: - Curated List

@Model
final class CuratedListData {
    @Attribute(.unique) var id: String
    var name: String
    var listDescription: String
    var imageUrl: String?
    var isDownloaded: Bool
    var version: Int
    var downloadedVersion: Int?
    var lastUpdated: Date
    var notifyWhenNearby: Bool

    var city: CityData?
    var curator: CuratorData?

    @Relationship(deleteRule: .cascade, inverse: \SpotData.list)
    var spots: [SpotData] = []

    /// Returns true if spots are cached locally but a newer version exists on the server
    var hasUpdate: Bool {
        guard let downloadedVersion = downloadedVersion else { return false }
        return version > downloadedVersion
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        listDescription: String = "",
        imageUrl: String? = nil,
        isDownloaded: Bool = false,
        version: Int = 1,
        downloadedVersion: Int? = nil,
        lastUpdated: Date = .now,
        notifyWhenNearby: Bool = false
    ) {
        self.id = id
        self.name = name
        self.listDescription = listDescription
        self.imageUrl = imageUrl
        self.isDownloaded = isDownloaded
        self.version = version
        self.downloadedVersion = downloadedVersion
        self.lastUpdated = lastUpdated
        self.notifyWhenNearby = notifyWhenNearby
    }
}

// MARK: - Spot (contains geofence coordinates)

@Model
final class SpotData {
    @Attribute(.unique) var id: String
    var name: String
    var spotDescription: String

    // Geofence coordinates
    var latitude: Double
    var longitude: Double

    // Optional metadata
    var instagramHandle: String?
    var websiteURL: String?

    var categoryData: SpotCategoryData?
    var list: CuratedListData?

    /// Backwards compatible: returns category name string
    var category: String {
        categoryData?.name ?? ""
    }

    /// Computed: Should this spot trigger geofence notifications?
    var isGeofenceActive: Bool {
        guard let list = list else { return false }
        return list.isDownloaded && list.notifyWhenNearby
    }

    var version: Int

    init(
        id: String = UUID().uuidString,
        name: String,
        spotDescription: String = "",
        latitude: Double,
        longitude: Double,
        categoryData: SpotCategoryData? = nil,
        instagramHandle: String? = nil,
        websiteURL: String? = nil,
        version: Int = 1
    ) {
        self.id = id
        self.name = name
        self.spotDescription = spotDescription
        self.latitude = latitude
        self.longitude = longitude
        self.categoryData = categoryData
        self.instagramHandle = instagramHandle
        self.websiteURL = websiteURL
        self.version = version
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
            radius: 400.0
        )
    }
}

extension CuratedListData {
    /// Get all spots as geofence configurations
    var geofenceConfigurations: [GeofenceConfiguration] {
        spots.map { $0.toGeofenceConfiguration() }
    }
}

// MARK: - Hashable Conformance for Navigation

extension CuratedListData: Hashable {
    static func == (lhs: CuratedListData, rhs: CuratedListData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension SpotData: Hashable {
    static func == (lhs: SpotData, rhs: SpotData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
