//
//  CuratorListsView.swift
//  Purpose: Shows all curated lists for a curator, grouped by city
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2026-04-03.
//

import SwiftUI
import SwiftData

struct CuratorListsView: View {
    let curator: CuratorData

    private var listsGroupedByCity: [(city: CityData?, lists: [CuratedListData])] {
        let grouped = Dictionary(grouping: curator.lists, by: { $0.city?.id })
        return grouped.map { (city: $0.value.first?.city, lists: $0.value.sorted { $0.name < $1.name }) }
            .sorted { ($0.city?.name ?? "") < ($1.city?.name ?? "") }
    }

    var body: some View {
        ListActionContainer { follow, stop in
            Group {
                if curator.lists.isEmpty {
                    ContentUnavailableView {
                        Label("No Lists", systemImage: "list.bullet")
                    } description: {
                        Text("No curated lists available")
                    }
                } else {
                    List {
                        ForEach(listsGroupedByCity, id: \.city?.id) { group in
                            let cityName = group.city != nil ? "\(group.city!.name), \(group.city!.country)" : "Lists"
                            Section {
                                ForEach(group.lists) { list in
                                    CuratedListRow(list: list, onFollow: { follow(list) }, onStop: { stop(list) }, navigable: false)
                                }
                            } header: {
                                Text(cityName)
                                    .textCase(nil)
                            }
                        }
                    }
                    .standardListStyle()
                }
            }
            .largeNavigationTitle(curator.name)
        }
    }
}

// MARK: - Preview

@MainActor
private func makeCuratorListsPreview() -> some View {
    let schema = Schema([CountryData.self, CityData.self, SpotCategoryData.self, CuratorData.self, CuratedListData.self, SpotData.self])
    let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let ctx = container.mainContext

    let country = CountryData(name: "France")
    let city = CityData(name: "Paris", countryData: country)
    let country2 = CountryData(name: "Japan")
    let city2 = CityData(name: "Tokyo", countryData: country2)
    let curator = CuratorData(name: "Marie Dupont", bio: "Parisian food lover and weekend wanderer.")

    let list1 = CuratedListData(name: "After Work Spots", isDownloaded: true, notifyWhenNearby: true)
    list1.city = city; list1.curator = curator

    let list2 = CuratedListData(name: "Weekend Brunch", isDownloaded: false)
    list2.city = city; list2.curator = curator

    let list3 = CuratedListData(name: "Hidden Gems", isDownloaded: false)
    list3.city = city2; list3.curator = curator

    ctx.insert(country); ctx.insert(country2)
    ctx.insert(city); ctx.insert(city2)
    ctx.insert(curator)
    [list1, list2, list3].forEach { ctx.insert($0) }

    return NavigationStack {
        CuratorListsView(curator: curator)
    }
    .modelContainer(container)
}

#Preview("Curator Lists") { makeCuratorListsPreview() }
