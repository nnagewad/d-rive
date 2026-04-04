//
//  LocationsView.swift
//  Purpose: Root locations screen — cities grouped by country, entry point for curated lists
//  Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-16.
//

import SwiftUI
import SwiftData

struct LocationsView: View {
    @Query(sort: \CityData.name) private var cities: [CityData]
    @State private var isLoading = false

    private var citiesGroupedByCountry: [(country: String, cities: [CityData])] {
        let grouped = Dictionary(grouping: cities, by: { $0.country })
        return grouped.map { (country: $0.key, cities: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.country < $1.country }
    }

    var body: some View {
        Group {
            if cities.isEmpty {
                ContentUnavailableView {
                    Label("Something went wrong", systemImage: "exclamationmark.triangle.fill")
                } description: {
                    Text("We couldn't load any lists.")
                } actions: {
                    Button(isLoading ? "Retrying…" : "Try Again") {
                        Task { await sync() }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isLoading)
                }
            } else {
                List {
                    ForEach(citiesGroupedByCountry, id: \.country) { group in
                        Section(group.country) {
                            ForEach(group.cities) { city in
                                NavigationLink(value: city) {
                                    Text(city.name)
                                }
                            }
                        }
                    }
                }
                .standardListStyle()
                .refreshable { await sync() }
            }
        }
        .largeNavigationTitle("Locations")
        .navigationDestination(for: CityData.self) { city in
            CityDetailView(city: city)
        }
        .navigationDestination(for: CuratedListData.self) { list in
            ListDetailView(list: list)
        }
        .navigationDestination(for: CuratorData.self) { curator in
            CuratorDetailView(curator: curator)
        }
    }

    // MARK: - Sync

    private func sync() async {
        isLoading = true
        defer { isLoading = false }
        try? await DataService.shared.syncFromSupabase()
    }
}

// MARK: - Preview

#Preview("With Cities") {
    NavigationStack {
        LocationsView()
    }
    .modelContainer({
        let schema = Schema([CountryData.self, CityData.self, SpotCategoryData.self, CuratorData.self, CuratedListData.self, SpotData.self])
        let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let ctx = container.mainContext

        let france = CountryData(name: "France")
        let uk = CountryData(name: "United Kingdom")
        [france, uk].forEach { ctx.insert($0) }

        [
            CityData(name: "Paris", countryData: france),
            CityData(name: "Lyon", countryData: france),
            CityData(name: "Marseille", countryData: france),
            CityData(name: "London", countryData: uk),
            CityData(name: "Manchester", countryData: uk),
            CityData(name: "Edinburgh", countryData: uk)
        ].forEach { ctx.insert($0) }

        return container
    }())
}

#Preview("No Connection") {
    NavigationStack {
        LocationsView()
    }
    .modelContainer({
        let schema = Schema([CountryData.self, CityData.self, SpotCategoryData.self, CuratorData.self, CuratedListData.self, SpotData.self])
        let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return container
    }())
}
