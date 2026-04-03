//
//  CityDetailView.swift
//  Purpose: Detail screen showing curated lists available for a specific city
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-16.
//

import SwiftUI
import SwiftData
struct CityDetailView: View {
    let city: CityData
    @Environment(\.openURL) private var openURL
    @State private var showPermissionAlert = false

    private var sectionHeader: String {
        city.lists.count == 1 ? "Curated list" : "Curated lists"
    }

    var body: some View {
        Group {
            if city.lists.isEmpty {
                ContentUnavailableView {
                    Label("No Lists", systemImage: "list.bullet")
                } description: {
                    Text("No curated lists available for this city")
                }
            } else {
                List {
                    Section(sectionHeader) {
                        ForEach(city.lists) { list in
                            CuratedListRow(list: list, onFollow: { followList(list) }, onStop: { stopList(list) })
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(city.name)
        .navigationBarTitleDisplayMode(.large)
        .alert("Notifications Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                openURL(URL(string: "app-settings:")!)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable notifications in Settings to receive alerts when you're near any  spots on this list.")
        }
    }

    // MARK: - Actions

    private func followList(_ list: CuratedListData) {
        Task {
            if !PermissionService.shared.hasRequestedLocationPermissions {
                _ = await PermissionService.shared.requestLocationPermission()
            }

            if !PermissionService.shared.hasRequestedNotificationPermissions {
                let granted = await PermissionService.shared.requestNotificationPermission()
                if !granted {
                    await MainActor.run { showPermissionAlert = true }
                    return
                }
            } else {
                await PermissionService.shared.refreshPermissionStatus()
                let hasNotifications = PermissionService.shared.notificationStatus == .authorized ||
                                      PermissionService.shared.notificationStatus == .provisional
                if !hasNotifications {
                    await MainActor.run { showPermissionAlert = true }
                    return
                }
            }

            await MainActor.run {
                DataService.shared.activateList(list)
                reloadGeofences()
            }
        }
    }

    private func stopList(_ list: CuratedListData) {
        list.notifyWhenNearby = false
        DataService.shared.save()
        reloadGeofences()
    }
}

// MARK: - Preview

@MainActor
private func makeCityDetailPreview() -> some View {
    let schema = Schema([CountryData.self, CityData.self, SpotCategoryData.self, CuratorData.self, CuratedListData.self, SpotData.self])
    let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let ctx = container.mainContext

    let country = CountryData(name: "France")
    let city = CityData(name: "Paris", countryData: country)
    let curator1 = CuratorData(name: "Marie Dupont", bio: "Parisian food lover")
    let curator2 = CuratorData(name: "Jean Martin", bio: "Night owl")
    let curator3 = CuratorData(name: "Sophie Bernard", bio: "Coffee addict")

    let list1 = CuratedListData(name: "After Work Spots", isDownloaded: true, notifyWhenNearby: true)
    list1.city = city
    list1.curator = curator1

    let list2 = CuratedListData(name: "Weekend Brunch", isDownloaded: false, notifyWhenNearby: false)
    list2.city = city
    list2.curator = curator2

    let list3 = CuratedListData(name: "Late Night Eats", isDownloaded: false, notifyWhenNearby: false)
    list3.city = city
    list3.curator = curator3

    ctx.insert(country)
    ctx.insert(city)
    [curator1, curator2, curator3].forEach { ctx.insert($0) }
    [list1, list2, list3].forEach { ctx.insert($0) }

    return NavigationStack {
        CityDetailView(city: city)
    }
    .modelContainer(container)
}

#Preview("City Detail") { makeCityDetailPreview() }
