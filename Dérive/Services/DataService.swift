//
//  DataService.swift
//  Dérive
//
//  Purpose: Manages SwiftData operations for the app
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

    // MARK: - Spot Operations

    func getAllSpots() -> [SpotData] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<SpotData>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func getSpotsForList(_ list: CuratedListData) -> [SpotData] {
        return list.spots.sorted { $0.name < $1.name }
    }

    func getActiveGeofenceSpots() -> [SpotData] {
        guard let context = modelContext else { return [] }
        // Get all spots from downloaded lists where notifications are enabled
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

    // MARK: - Download Management

    func downloadList(_ list: CuratedListData) {
        list.isDownloaded = true
        list.lastUpdated = .now
        save()
        logger.info("Downloaded list: \(list.name)")
    }

    func removeDownloadedList(_ list: CuratedListData) {
        list.isDownloaded = false
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

    func getGeofenceConfigurations() -> [GeofenceConfiguration] {
        return getActiveGeofenceSpots().map { $0.toGeofenceConfiguration() }
    }

    func getActiveGeofenceCount() -> Int {
        return getActiveGeofenceSpots().count
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

    // MARK: - Sample Data Seeding

    func seedSampleDataIfNeeded() {
        guard let context = modelContext else { return }

        // Check if data already exists
        let cityDescriptor = FetchDescriptor<CityData>()
        let existingCities = (try? context.fetch(cityDescriptor)) ?? []

        if !existingCities.isEmpty {
            logger.info("Data already exists, skipping seed")
            return
        }

        logger.info("Seeding sample data...")
        seedSampleData(in: context)
    }

    private func seedSampleData(in context: ModelContext) {
        // Create city
        let london = CityData(name: "London", country: "United Kingdom")

        // Create curator
        let nikin = CuratorData(
            name: "Nikin",
            bio: "Just testing this out...",
            instagramHandle: "nkngwd"
        )

        // London test list
        let localLondon = CuratedListData(
            name: "Local London",
            listDescription: "Testing out London spots",
            isDownloaded: true,
            notifyWhenNearby: false
        )
        localLondon.city = london
        localLondon.curator = nikin

        // London spots
        let woodsidePark = SpotData(
            name: "Woodside Park",
            category: "Tube",
            latitude: 51.618013264233035,
            longitude: -0.18540148337268103
        )
        woodsidePark.list = localLondon

        let waitrose = SpotData(
            name: "Waitrose",
            category: "Grocery",
            latitude: 51.61142155607026,
            longitude: -0.1800797471589078
        )
        waitrose.list = localLondon

        let barbican = SpotData(
            name: "Barbican Centre",
            category: "Culture Spot",
            latitude: 51.52020665887417,
            longitude: -0.09379285593545097
        )
        barbican.list = localLondon

        // Testing again list
        let testingAgain = CuratedListData(
            name: "Testing again",
            listDescription: "Testing another list",
            isDownloaded: false,
            notifyWhenNearby: false
        )
        testingAgain.city = london
        testingAgain.curator = nikin

        let holybella = SpotData(
            name: "Holybella",
            category: "Restaurant",
            latitude: 51.61844648383398,
            longitude: -0.17644401361052559,
            instagramHandle: "holybella_london"
        )
        holybella.list = testingAgain

        // Toronto
        let toronto = CityData(name: "Toronto", country: "Canada")

        let torontoTest = CuratedListData(
            name: "Toronto test",
            listDescription: "Testing Toronto",
            isDownloaded: false,
            notifyWhenNearby: false
        )
        torontoTest.city = toronto
        torontoTest.curator = nikin

        let bellwoodsBrewery = SpotData(
            name: "Bellwoods Brewery",
            category: "Microbrewery",
            latitude: 43.64710818482737,
            longitude: -79.4200139868096,
            instagramHandle: "bellwoodsbeer"
        )
        bellwoodsBrewery.list = torontoTest

        // Insert entities
        context.insert(london)
        context.insert(toronto)
        context.insert(nikin)
        context.insert(localLondon)
        context.insert(testingAgain)
        context.insert(torontoTest)

        do {
            try context.save()
            logger.info("Sample data seeded successfully")
        } catch {
            logger.error("Failed to seed sample data: \(error.localizedDescription)")
        }
    }

    // MARK: - Debug

    func clearAllData() {
        guard let context = modelContext else { return }

        do {
            try context.delete(model: SpotData.self)
            try context.delete(model: CuratedListData.self)
            try context.delete(model: CuratorData.self)
            try context.delete(model: CityData.self)
            try context.save()
            logger.info("All data cleared")
        } catch {
            logger.error("Failed to clear data: \(error.localizedDescription)")
        }
    }
}
