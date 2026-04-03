//
//  CuratorDetailView.swift
//  Purpose: Detail screen for a curator — bio, Instagram, and their curated lists
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-16.
//

import SwiftUI
import SwiftData

struct CuratorDetailView: View {
    let curator: CuratorData
    @Environment(\.openURL) private var openURL
    @State private var showPermissionAlert = false

    private var listsGroupedByCity: [(city: CityData?, lists: [CuratedListData])] {
        let grouped = Dictionary(grouping: curator.lists, by: { $0.city?.id })
        return grouped.map { (city: $0.value.first?.city, lists: $0.value.sorted { $0.name < $1.name }) }
            .sorted { ($0.city?.name ?? "") < ($1.city?.name ?? "") }
    }

    var body: some View {
        List {
            if !curator.bio.isEmpty || curator.instagramHandle != nil {
                Section("About") {
                    if !curator.bio.isEmpty {
                        Text(curator.bio)
                    }

                    if let instagram = curator.instagramHandle {
                        Button("Instagram") {
                            openInstagram(instagram)
                        }
                    }

                    if let website = curator.websiteURL {
                        Button("Website") {
                            openWebsite(website)
                        }
                    }
                }
            }

            if !curator.lists.isEmpty {
                ForEach(Array(listsGroupedByCity.enumerated()), id: \.element.city?.id) { index, group in
                    let cityName = group.city != nil ? "\(group.city!.name), \(group.city!.country)" : "Lists"
                    Section {
                        ForEach(group.lists) { list in
                            CuratedListRow(list: list, onFollow: { followList(list) }, onStop: { stopList(list) })
                        }
                    } header: {
                        if index == 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(curator.lists.count == 1 ? "Curator's list" : "Curator's lists")
                                    .font(.title3.bold())
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                Text(cityName)
                                    .textCase(nil)
                            }
                        } else {
                            Text(cityName)
                                .textCase(nil)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(curator.name)
        .navigationBarTitleDisplayMode(.large)
        .alert("Notifications Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                openURL(URL(string: "app-settings:")!)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable notifications in Settings to receive alerts when you're near any spots on this list.")
        }
    }

    // MARK: - Actions

    private func followList(_ list: CuratedListData) {
        Task {
            if !(await ListActionService.shared.follow(list)) {
                showPermissionAlert = true
            }
        }
    }

    private func stopList(_ list: CuratedListData) {
        ListActionService.shared.stop(list)
    }

    private func openInstagram(_ value: String) {
        let urlString = value.hasPrefix("http") ? value : "https://instagram.com/\(value.trimmingCharacters(in: .init(charactersIn: "@")))"
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }

    private func openWebsite(_ urlString: String) {
        let prefixed = urlString.hasPrefix("http") ? urlString : "https://\(urlString)"
        if let url = URL(string: prefixed) {
            openURL(url)
        }
    }
}

// MARK: - Preview

@MainActor
private func makeCuratorDetailPreview() -> some View {
    let schema = Schema([CountryData.self, CityData.self, SpotCategoryData.self, CuratorData.self, CuratedListData.self, SpotData.self])
    let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let ctx = container.mainContext

    let country = CountryData(name: "France")
    let city = CityData(name: "Paris", countryData: country)
    let curator = CuratorData(
        name: "Marie Dupont",
        bio: "Parisian food lover and weekend wanderer.",
        instagramHandle: "@mariedupont",
        websiteURL: "https://mariedupont.com"
    )

    let country2 = CountryData(name: "Japan")
    let city2 = CityData(name: "Tokyo", countryData: country2)

    let list1 = CuratedListData(name: "After Work Spots", isDownloaded: true, notifyWhenNearby: true)
    list1.city = city
    list1.curator = curator

    let list2 = CuratedListData(name: "Weekend Brunch", isDownloaded: false)
    list2.city = city
    list2.curator = curator

    let list3 = CuratedListData(name: "Hidden Gems", isDownloaded: false)
    list3.city = city2
    list3.curator = curator

    ctx.insert(country)
    ctx.insert(country2)
    ctx.insert(city)
    ctx.insert(city2)
    ctx.insert(curator)
    [list1, list2, list3].forEach { ctx.insert($0) }

    return NavigationStack {
        CuratorDetailView(curator: curator)
    }
    .modelContainer(container)
}

@MainActor
private func makeCuratorDetailSingleListPreview() -> some View {
    let schema = Schema([CountryData.self, CityData.self, SpotCategoryData.self, CuratorData.self, CuratedListData.self, SpotData.self])
    let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let ctx = container.mainContext

    let country = CountryData(name: "France")
    let city = CityData(name: "Paris", countryData: country)
    let curator = CuratorData(
        name: "Marie Dupont",
        bio: "Parisian food lover and weekend wanderer.",
        instagramHandle: "@mariedupont"
    )

    let list = CuratedListData(name: "After Work Spots", isDownloaded: false)
    list.city = city
    list.curator = curator

    ctx.insert(country)
    ctx.insert(city)
    ctx.insert(curator)
    ctx.insert(list)

    return NavigationStack {
        CuratorDetailView(curator: curator)
    }
    .modelContainer(container)
}

#Preview("Curator Detail — Multiple Lists") { makeCuratorDetailPreview() }
#Preview("Curator Detail — Single List") { makeCuratorDetailSingleListPreview() }
