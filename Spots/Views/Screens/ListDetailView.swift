//
//  ListDetailView.swift
//  Purpose: Detail screen for a curated list — spots, curator info, and notification activation
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-16.
//

import SwiftUI
import SwiftData
import os.log

struct ListDetailView: View {
    private let logger = Logger(subsystem: "com.nikin.spots", category: "ListDetailView")
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Bindable var list: CuratedListData
    @State private var isLoadingSpots = false
    @State private var spotsLoadError: Error?
    @State private var isActivating = false
    @State private var showPermissionAlert = false
    @State private var selectedSpot: SpotData?

    private var isActivated: Bool {
        list.isDownloaded && list.notifyWhenNearby
    }

    var body: some View {
        List {
            // Description
            if !list.listDescription.isEmpty {
                Section("About this list") {
                    Text(list.listDescription)
                }
            }

            // Spots Section
            Section("Spots") {
                if isLoadingSpots {
                    ProgressView().frame(maxWidth: .infinity)
                } else if let error = spotsLoadError {
                    Text("Failed to load spots: \(error.localizedDescription)")
                        .foregroundStyle(.secondary)
                } else if list.spots.isEmpty {
                    Text("No spots available")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(list.spots) { spot in
                        SpotRow(name: spot.name) {
                            selectedSpot = spot
                        }
                    }
                }
            }

            // Curator Section
            if let curator = list.curator {
                Section("List curated by") {
                    NavigationLink(value: curator) {
                        Text(curator.name)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadSpots()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isActivating {
                    ProgressView()
                } else if isActivated {
                    Button {
                        deactivateList()
                    } label: {
                        Image(systemName: "bell.slash.fill")
                    }
                    .buttonBorderShape(.circle)
                } else {
                    Button {
                        activateList()
                    } label: {
                        Image(systemName: "bell.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .disabled(isLoadingSpots)
                }
            }
        }
        .alert("Notifications Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                openURL(URL(string: "app-settings:")!)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable notifications in Settings to receive alerts when you're near saved spots.")
        }
        .sheet(item: $selectedSpot) { spot in
            SpotDetailSheet(spot: spot) {
                selectedSpot = nil
            }
        }
    }

    // MARK: - Spots Loading

    private func loadSpots() async {
        guard list.spots.isEmpty else { return }

        isLoadingSpots = true
        spotsLoadError = nil

        do {
            try await DataService.shared.fetchSpotsForList(list)
        } catch {
            spotsLoadError = error
            logger.error("Failed to load spots: \(error.localizedDescription)")
        }

        isLoadingSpots = false
    }

    // MARK: - Activation

    private func activateList() {
        isActivating = true
        Task {
            if !PermissionService.shared.hasRequestedLocationPermissions {
                _ = await PermissionService.shared.requestLocationPermission()
            }

            if !PermissionService.shared.hasRequestedNotificationPermissions {
                let granted = await PermissionService.shared.requestNotificationPermission()
                if !granted {
                    await MainActor.run {
                        isActivating = false
                        showPermissionAlert = true
                    }
                    return
                }
            } else {
                await PermissionService.shared.refreshPermissionStatus()
                let hasNotifications = PermissionService.shared.notificationStatus == .authorized ||
                                      PermissionService.shared.notificationStatus == .provisional
                if !hasNotifications {
                    await MainActor.run {
                        isActivating = false
                        showPermissionAlert = true
                    }
                    return
                }
            }

            await MainActor.run {
                DataService.shared.activateList(list)
                isActivating = false
                reloadGeofences()
            }
        }
    }

    private func deactivateList() {
        list.notifyWhenNearby = false
        DataService.shared.save()
        reloadGeofences()
    }
}

// MARK: - Preview

@MainActor
private func makePreviewContainer(notifyWhenNearby: Bool) -> some View {
    let schema = Schema([CountryData.self, CityData.self, SpotCategoryData.self, CuratorData.self, CuratedListData.self, SpotData.self])
    let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let ctx = container.mainContext

    let curator = CuratorData(name: "Marie Dupont", bio: "Parisian food lover")
    let list = CuratedListData(
        name: "After Work Spots",
        listDescription: "After my shift these are my favourite spots to go to. A lot of unknowns but the food and the atmosphere is incredible.",
        isDownloaded: notifyWhenNearby,
        notifyWhenNearby: notifyWhenNearby
    )
    list.curator = curator

    let spots = [
        SpotData(name: "Café de Flore", latitude: 48.8540, longitude: 2.3327),
        SpotData(name: "Le Comptoir du Relais", latitude: 48.8534, longitude: 2.3403),
        SpotData(name: "Septime", latitude: 48.8527, longitude: 2.3791)
    ]
    spots.forEach { $0.list = list }
    ctx.insert(curator)
    ctx.insert(list)
    spots.forEach { ctx.insert($0) }

    return NavigationStack {
        ListDetailView(list: list)
    }
    .modelContainer(container)
}

#Preview("Not Following") { makePreviewContainer(notifyWhenNearby: false) }
#Preview("Following") { makePreviewContainer(notifyWhenNearby: true) }
