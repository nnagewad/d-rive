//
//  City.swift
//  Dérive
//
//  Purpose: Data models for city manifest and individual cities
//

import Foundation

/// Represents a city in the manifest
struct City: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let country: String
    let fileName: String
    let version: String
    let geofenceCount: Int
    let isPremium: Bool
}

/// The manifest containing all available cities
struct CityManifest: Codable, Sendable {
    let version: String
    let cities: [City]
}

/// City geofence data (the actual JSON file for a city)
struct CityGeofenceData: Codable, Sendable {
    let version: String
    let defaultRadius: Double
    let city: String
    let geofences: [CityGeofence]
}

/// Individual geofence within a city (for decoding)
struct CityGeofence: Codable, Sendable {
    let id: String
    let name: String
    let group: String
    let latitude: Double
    let longitude: Double
}
