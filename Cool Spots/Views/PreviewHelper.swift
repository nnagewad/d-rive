//
//  PreviewHelper.swift
//  Purpose: Shared SwiftData container factory for Xcode previews
//  Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2026-04-04.
//

import SwiftData

@MainActor
enum PreviewContainer {
    static var container: ModelContainer {
        let schema = Schema([
            CountryData.self, CityData.self, SpotCategoryData.self,
            CuratorData.self, CuratedListData.self, SpotData.self
        ])
        return try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    }

    static var containerWithData: ModelContainer {
        let container = self.container
        let context = container.mainContext

        let country = CountryData(name: "Canada")
        let city = CityData(name: "Toronto", countryData: country)
        let curator = CuratorData(name: "Local Expert", bio: "Toronto native")

        let list = CuratedListData(
            name: "Coffee Spots",
            listDescription: "Best coffee in Toronto",
            isDownloaded: true,
            notifyWhenNearby: true
        )
        list.city = city
        list.curator = curator

        let spots = [
            SpotData(name: "Sam James Coffee Bar", latitude: 43.6544, longitude: -79.4055),
            SpotData(name: "Pilot Coffee Roasters", latitude: 43.6465, longitude: -79.3963),
            SpotData(name: "Boxcar Social", latitude: 43.6677, longitude: -79.3901)
        ]
        spots.forEach { $0.list = list }

        context.insert(country)
        context.insert(city)
        context.insert(curator)
        context.insert(list)
        spots.forEach { context.insert($0) }

        return container
    }
}
