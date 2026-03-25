//
//  DataService.swift
//  Purpose: Manages SwiftData operations and syncs with Supabase
//  Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2026-01-19.
//

import Foundation
import SwiftData
import os.log

@MainActor
final class DataService {

    static let shared = DataService()

    private let logger = Logger(subsystem: "com.nikin.spots", category: "DataService")

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
                websiteURL: supabaseSpot.websiteUrl,
                version: supabaseSpot.version
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

    /// Fetches spots for a list without activating geofencing
    /// Used to display spots before user activates the list
    func fetchSpotsForList(_ list: CuratedListData) async throws {
        guard let context = modelContext else {
            logger.error("No model context available for fetching spots")
            return
        }

        // Skip if spots already loaded
        guard list.spots.isEmpty else {
            logger.debug("Spots already loaded for list: \(list.name)")
            return
        }

        logger.info("Fetching spots for preview: \(list.name)...")

        let listUUID = UUID(uuidString: list.id)!
        let supabaseSpots = try await SupabaseService.shared.fetchSpots(forListId: listUUID)

        for supabaseSpot in supabaseSpots {
            let spot = SpotData(
                id: supabaseSpot.id.uuidString,
                name: supabaseSpot.spotName,
                spotDescription: supabaseSpot.spotDescription,
                latitude: supabaseSpot.latitude,
                longitude: supabaseSpot.longitude,
                instagramHandle: supabaseSpot.instagramHandle,
                websiteURL: supabaseSpot.websiteUrl,
                version: supabaseSpot.version
            )

            if let categoryId = supabaseSpot.categoryId?.uuidString {
                spot.categoryData = getSpotCategory(byId: categoryId)
            }

            spot.list = list
            context.insert(spot)
        }

        // Track the version we fetched at so future updates can be detected
        list.downloadedVersion = list.version

        try context.save()
        logger.info("Fetched \(supabaseSpots.count) spots for preview: \(list.name)")
    }

    /// Activates a list: sets both isDownloaded and notifyWhenNearby flags
    /// Spots should already be fetched via fetchSpotsForList()
    func activateList(_ list: CuratedListData) {
        list.isDownloaded = true
        list.notifyWhenNearby = true
        list.downloadedVersion = list.version
        list.lastUpdated = .now
        save()
        logger.info("Activated list: \(list.name)")
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

        // Build ID sets for deletion checks
        let remoteCountryIds = Set(countries.map { $0.id.uuidString })
        let remoteCategoryIds = Set(categories.map { $0.id.uuidString })
        let remoteCuratorIds = Set(curators.map { $0.id.uuidString })
        let remoteCityIds = Set(cities.map { $0.id.uuidString })
        let remoteListIds = Set(lists.map { $0.id.uuidString })

        // Sync countries
        for supabaseCountry in countries {
            let id = supabaseCountry.id.uuidString
            if let existing = getCountry(byId: id) {
                if supabaseCountry.version > existing.version {
                    existing.name = supabaseCountry.countryName
                    existing.version = supabaseCountry.version
                }
            } else {
                context.insert(CountryData(id: id, name: supabaseCountry.countryName, version: supabaseCountry.version))
            }
        }

        // Sync spot categories
        for supabaseCategory in categories {
            let id = supabaseCategory.id.uuidString
            if let existing = getSpotCategory(byId: id) {
                if supabaseCategory.version > existing.version {
                    existing.name = supabaseCategory.categoryName
                    existing.version = supabaseCategory.version
                }
            } else {
                context.insert(SpotCategoryData(id: id, name: supabaseCategory.categoryName, version: supabaseCategory.version))
            }
        }

        // Sync curators
        for supabaseCurator in curators {
            let id = supabaseCurator.id.uuidString
            if let existing = getCurator(byId: id) {
                if supabaseCurator.version > existing.version {
                    existing.name = supabaseCurator.curatorName
                    existing.bio = supabaseCurator.curatorBio
                    existing.imageUrl = supabaseCurator.imageUrl
                    existing.instagramHandle = supabaseCurator.instagramHandle
                    existing.version = supabaseCurator.version
                }
            } else {
                context.insert(CuratorData(
                    id: id,
                    name: supabaseCurator.curatorName,
                    bio: supabaseCurator.curatorBio,
                    imageUrl: supabaseCurator.imageUrl,
                    instagramHandle: supabaseCurator.instagramHandle,
                    version: supabaseCurator.version
                ))
            }
        }

        // Save to ensure countries, categories, and curators are available
        try context.save()

        // Sync cities
        for supabaseCity in cities {
            let id = supabaseCity.id.uuidString
            let countryId = supabaseCity.countryId?.uuidString

            if let existing = getCity(byId: id) {
                if supabaseCity.version > existing.version {
                    existing.name = supabaseCity.cityName
                    existing.version = supabaseCity.version
                    if let countryId { existing.countryData = getCountry(byId: countryId) }
                }
            } else {
                let city = CityData(id: id, name: supabaseCity.cityName, version: supabaseCity.version)
                if let countryId { city.countryData = getCountry(byId: countryId) }
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
                if let lastUpdated = supabaseList.lastUpdated { existing.lastUpdated = lastUpdated }
                if let cityId { existing.city = getCity(byId: cityId) }
                if let curatorId { existing.curator = getCurator(byId: curatorId) }
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
                if let cityId { list.city = getCity(byId: cityId) }
                if let curatorId { list.curator = getCurator(byId: curatorId) }
                context.insert(list)
            }
        }

        // Delete records removed from Supabase (most dependent first)
        for list in getAllLists() where !remoteListIds.contains(list.id) {
            list.spots.forEach { context.delete($0) }
            context.delete(list)
            logger.info("Deleted removed list: \(list.name)")
        }
        for city in getAllCities() where !remoteCityIds.contains(city.id) {
            context.delete(city)
        }
        for curator in getAllCurators() where !remoteCuratorIds.contains(curator.id) {
            context.delete(curator)
        }
        for category in getAllSpotCategories() where !remoteCategoryIds.contains(category.id) {
            context.delete(category)
        }
        for country in getAllCountries() where !remoteCountryIds.contains(country.id) {
            context.delete(country)
        }

        // Final save
        try context.save()

        logger.info("Supabase metadata sync completed: \(countries.count) countries, \(cities.count) cities, \(categories.count) categories, \(curators.count) curators, \(lists.count) lists")

        // Check for downloaded lists that have updates and refresh their spots
        try await syncDownloadedListsWithUpdates()
    }

    /// Checks all locally cached lists for version updates and re-fetches spots if needed
    private func syncDownloadedListsWithUpdates() async throws {
        let listsWithUpdates = getAllLists().filter { $0.hasUpdate && !$0.spots.isEmpty }

        guard !listsWithUpdates.isEmpty else {
            logger.debug("No cached lists need updates")
            return
        }

        logger.info("Found \(listsWithUpdates.count) list(s) with updates, syncing spots...")

        var geofencesNeedReload = false

        for list in listsWithUpdates {
            logger.info("Updating spots for list: \(list.name) (v\(list.downloadedVersion ?? 0) → v\(list.version))")
            if list.isDownloaded {
                // Full re-download: refreshes spots and preserves activated state
                try await downloadListFromSupabase(list)
                geofencesNeedReload = true
            } else {
                // Preview refresh: update spots without activating the list
                try await refreshPreviewSpots(list)
            }
        }

        if geofencesNeedReload {
            GeofenceLoaderService.shared.reloadAndRestartMonitoring()
        }

        logger.info("Completed updating \(listsWithUpdates.count) list(s)")
    }

    /// Refreshes spots for a previewed (non-activated) list without changing its download state
    private func refreshPreviewSpots(_ list: CuratedListData) async throws {
        guard let context = modelContext else { return }

        let listUUID = UUID(uuidString: list.id)!
        let supabaseSpots = try await SupabaseService.shared.fetchSpots(forListId: listUUID)

        for spot in list.spots { context.delete(spot) }

        for supabaseSpot in supabaseSpots {
            let spot = SpotData(
                id: supabaseSpot.id.uuidString,
                name: supabaseSpot.spotName,
                spotDescription: supabaseSpot.spotDescription,
                latitude: supabaseSpot.latitude,
                longitude: supabaseSpot.longitude,
                instagramHandle: supabaseSpot.instagramHandle,
                websiteURL: supabaseSpot.websiteUrl,
                version: supabaseSpot.version
            )
            if let categoryId = supabaseSpot.categoryId?.uuidString {
                spot.categoryData = getSpotCategory(byId: categoryId)
            }
            spot.list = list
            context.insert(spot)
        }

        list.downloadedVersion = list.version
        list.lastUpdated = .now
        try context.save()
        logger.info("Refreshed preview spots for list: \(list.name) with \(supabaseSpots.count) spots")
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
