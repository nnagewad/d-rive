//
//  DataService.swift
//  Purpose: Manages SwiftData operations and syncs with Supabase
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2026-01-19.
//

import Foundation
import SwiftData
import os.log

@MainActor
final class DataService {

    static let shared = DataService()

    private let logger = Logger(subsystem: "com.derive.app", category: "DataService")

    private var modelContainer: ModelContainer?

    private init() {}

    // MARK: - Setup

    func configure(with container: ModelContainer) {
        self.modelContainer = container
        logger.info("DataService configured with ModelContainer")
    }

    // MARK: - Context Access

    var modelContext: ModelContext? {
        modelContainer?.mainContext
    }

    // MARK: - Country Operations

    func getAllCountries() -> [CountryData] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<CountryData>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func getCountry(byId id: String) -> CountryData? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<CountryData>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    // MARK: - City Operations

    func getAllCities() -> [CityData] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<CityData>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func getCity(byId id: String) -> CityData? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<CityData>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    // MARK: - Spot Category Operations

    func getAllSpotCategories() -> [SpotCategoryData] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<SpotCategoryData>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func getSpotCategory(byId id: String) -> SpotCategoryData? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<SpotCategoryData>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    // MARK: - Curated List Operations

    func getAllLists() -> [CuratedListData] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<CuratedListData>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func getDownloadedLists() -> [CuratedListData] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<CuratedListData>(
            predicate: #Predicate { $0.isDownloaded == true },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func getListsForCity(_ city: CityData) -> [CuratedListData] {
        guard let context = modelContext else { return [] }
        let cityId = city.id
        let descriptor = FetchDescriptor<CuratedListData>(
            predicate: #Predicate { $0.city?.id == cityId },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func getList(byId id: String) -> CuratedListData? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<CuratedListData>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    // MARK: - Spot Operations

    func getAllSpots() -> [SpotData] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<SpotData>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func getSpotsForList(_ list: CuratedListData) -> [SpotData] {
        return list.spots.sorted { $0.name < $1.name }
    }

    func getSpot(byId id: String) -> SpotData? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<SpotData>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    /// Returns all spots from downloaded lists (for display in Nearby Spots)
    func getDownloadedSpots() -> [SpotData] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<SpotData>(
            predicate: #Predicate {
                $0.list?.isDownloaded == true
            }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Returns spots that should trigger iOS notifications (downloaded + notify enabled)
    func getNotificationGeofenceSpots() -> [SpotData] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<SpotData>(
            predicate: #Predicate {
                $0.list?.isDownloaded == true && $0.list?.notifyWhenNearby == true
            }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Curator Operations

    func getAllCurators() -> [CuratorData] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<CuratorData>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func getCurator(byId id: String) -> CuratorData? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<CuratorData>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    // MARK: - Download Management

    /// Downloads a list and its spots from Supabase
    func downloadListFromSupabase(_ list: CuratedListData) async throws {
        guard let context = modelContext else {
            logger.error("No model context available for download")
            return
        }

        logger.info("Downloading list: \(list.name)...")

        // Fetch spots for this list from Supabase
        let listUUID = UUID(uuidString: list.id)!
        let supabaseSpots = try await SupabaseService.shared.fetchSpots(forListId: listUUID)

        // Clear existing local spots for this list (in case of update)
        for spot in list.spots {
            context.delete(spot)
        }

        // Add new spots from Supabase
        for supabaseSpot in supabaseSpots {
            let spot = SpotData(
                id: supabaseSpot.id.uuidString,
                name: supabaseSpot.spotName,
                spotDescription: supabaseSpot.spotDescription,
                latitude: supabaseSpot.latitude,
                longitude: supabaseSpot.longitude,
                instagramHandle: supabaseSpot.instagramHandle,
                websiteURL: supabaseSpot.websiteUrl
            )

            // Link category if available
            if let categoryId = supabaseSpot.categoryId?.uuidString {
                spot.categoryData = getSpotCategory(byId: categoryId)
            }

            spot.list = list
            context.insert(spot)
        }

        // Mark as downloaded with current version
        list.isDownloaded = true
        list.downloadedVersion = list.version
        list.lastUpdated = .now

        try context.save()
        logger.info("Downloaded list: \(list.name) with \(supabaseSpots.count) spots")
    }

    func removeDownloadedList(_ list: CuratedListData) {
        guard let context = modelContext else { return }

        // Delete local spots for this list
        for spot in list.spots {
            context.delete(spot)
        }

        list.isDownloaded = false
        list.downloadedVersion = nil
        list.notifyWhenNearby = false
        save()
        logger.info("Removed downloaded list: \(list.name)")
    }

    func toggleNotifications(for list: CuratedListData) {
        list.notifyWhenNearby.toggle()
        save()
        logger.info("Toggled notifications for \(list.name): \(list.notifyWhenNearby)")
    }

    // MARK: - Geofence Integration

    /// Returns configurations for iOS geofence registration (only spots with notifications enabled)
    func getGeofenceConfigurations() -> [GeofenceConfiguration] {
        return getNotificationGeofenceSpots().map { $0.toGeofenceConfiguration() }
    }

    /// Returns count of all downloaded spots (displayed in UI)
    func getDownloadedSpotCount() -> Int {
        return getDownloadedSpots().count
    }

    // MARK: - Persistence

    func save() {
        guard let context = modelContext else { return }
        do {
            try context.save()
            logger.debug("Context saved successfully")
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
        }
    }

    // MARK: - Supabase Sync

    /// Syncs metadata from Supabase (countries, cities, categories, curators, lists)
    /// Does NOT sync spots — those are fetched on-demand when user downloads a list
    func syncFromSupabase() async throws {
        guard let context = modelContext else {
            logger.error("No model context available for sync")
            return
        }

        logger.info("Starting Supabase metadata sync...")

        // Fetch metadata from Supabase (not spots)
        async let countriesTask = SupabaseService.shared.fetchCountries()
        async let citiesTask = SupabaseService.shared.fetchCities()
        async let categoriesTask = SupabaseService.shared.fetchSpotCategories()
        async let curatorsTask = SupabaseService.shared.fetchCurators()
        async let listsTask = SupabaseService.shared.fetchCuratedLists()

        let (countries, cities, categories, curators, lists) = try await (
            countriesTask, citiesTask, categoriesTask, curatorsTask, listsTask
        )

        // Sync countries
        for supabaseCountry in countries {
            let id = supabaseCountry.id.uuidString
            if let existing = getCountry(byId: id) {
                existing.name = supabaseCountry.countryName
            } else {
                let country = CountryData(id: id, name: supabaseCountry.countryName)
                context.insert(country)
            }
        }

        // Sync spot categories
        for supabaseCategory in categories {
            let id = supabaseCategory.id.uuidString
            if let existing = getSpotCategory(byId: id) {
                existing.name = supabaseCategory.categoryName
            } else {
                let category = SpotCategoryData(id: id, name: supabaseCategory.categoryName)
                context.insert(category)
            }
        }

        // Sync curators
        for supabaseCurator in curators {
            let id = supabaseCurator.id.uuidString
            if let existing = getCurator(byId: id) {
                existing.name = supabaseCurator.curatorName
                existing.bio = supabaseCurator.curatorBio
                existing.imageUrl = supabaseCurator.imageUrl
                existing.instagramHandle = supabaseCurator.instagramHandle
            } else {
                let curator = CuratorData(
                    id: id,
                    name: supabaseCurator.curatorName,
                    bio: supabaseCurator.curatorBio,
                    imageUrl: supabaseCurator.imageUrl,
                    instagramHandle: supabaseCurator.instagramHandle
                )
                context.insert(curator)
            }
        }

        // Save to ensure countries, categories, and curators are available
        try context.save()

        // Sync cities
        for supabaseCity in cities {
            let id = supabaseCity.id.uuidString
            let countryId = supabaseCity.countryId?.uuidString

            if let existing = getCity(byId: id) {
                existing.name = supabaseCity.cityName
                if let countryId = countryId {
                    existing.countryData = getCountry(byId: countryId)
                }
            } else {
                let city = CityData(id: id, name: supabaseCity.cityName)
                if let countryId = countryId {
                    city.countryData = getCountry(byId: countryId)
                }
                context.insert(city)
            }
        }

        // Save to ensure cities are available
        try context.save()

        // Sync curated lists
        for supabaseList in lists {
            let id = supabaseList.id.uuidString
            let cityId = supabaseList.cityId?.uuidString
            let curatorId = supabaseList.curatorId?.uuidString

            if let existing = getList(byId: id) {
                existing.name = supabaseList.listName
                existing.listDescription = supabaseList.listDescription
                existing.imageUrl = supabaseList.imageUrl
                existing.version = supabaseList.version
                if let lastUpdated = supabaseList.lastUpdated {
                    existing.lastUpdated = lastUpdated
                }
                if let cityId = cityId {
                    existing.city = getCity(byId: cityId)
                }
                if let curatorId = curatorId {
                    existing.curator = getCurator(byId: curatorId)
                }
            } else {
                let list = CuratedListData(
                    id: id,
                    name: supabaseList.listName,
                    listDescription: supabaseList.listDescription,
                    imageUrl: supabaseList.imageUrl,
                    isDownloaded: false,
                    version: supabaseList.version,
                    lastUpdated: supabaseList.lastUpdated ?? .now,
                    notifyWhenNearby: false
                )
                if let cityId = cityId {
                    list.city = getCity(byId: cityId)
                }
                if let curatorId = curatorId {
                    list.curator = getCurator(byId: curatorId)
                }
                context.insert(list)
            }
        }

        // Final save
        try context.save()

        logger.info("Supabase metadata sync completed: \(countries.count) countries, \(cities.count) cities, \(categories.count) categories, \(curators.count) curators, \(lists.count) lists")
    }

    // MARK: - Debug

    func clearAllData() {
        guard let context = modelContext else { return }

        do {
            try context.delete(model: SpotData.self)
            try context.delete(model: CuratedListData.self)
            try context.delete(model: CuratorData.self)
            try context.delete(model: CityData.self)
            try context.delete(model: SpotCategoryData.self)
            try context.delete(model: CountryData.self)
            try context.save()
            logger.info("All data cleared")
        } catch {
            logger.error("Failed to clear data: \(error.localizedDescription)")
        }
    }
}
