import SwiftUI
import SwiftData
import UIKit

// MARK: - Curated Lists View

/// Main screen showing all available curated lists grouped by city
/// Tab 2 in the app navigation
struct CuratedListsView: View {
    @Query(sort: \CityData.name) private var cities: [CityData]
    @State private var selectedList: CuratedListData?
    @State private var navigationPath = NavigationPath()

    private var citiesGroupedByCountry: [(country: String, cities: [CityData])] {
        let grouped = Dictionary(grouping: cities, by: { $0.country })
        return grouped.map { (country: $0.key, cities: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.country < $1.country }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if cities.isEmpty {
                    emptyState
                } else {
                    citiesListContent
                }
            }
            .navigationTitle("Curated Lists")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: CityData.self) { city in
                CityDetailView(city: city, navigationPath: $navigationPath)
            }
            .navigationDestination(for: CuratedListData.self) { list in
                ListDetailView(list: list, navigationPath: $navigationPath)
            }
            .navigationDestination(for: CuratorData.self) { curator in
                CuratorDetailView(curator: curator, navigationPath: $navigationPath)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Curated Lists", systemImage: "list.bullet.clipboard")
        } description: {
            Text("Browse and download lists to get started")
        }
    }

    // MARK: - Cities List Content

    private var citiesListContent: some View {
        List {
            ForEach(citiesGroupedByCountry, id: \.country) { group in
                Section(group.country) {
                    ForEach(group.cities) { city in
                        NavigationLink(value: city) {
                            Text(city.name)
                        }
                        .listRowBackground(Color.backgroundGroupedSecondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

}

// MARK: - City Detail View

/// Detail view showing curated lists for a specific city
/// Displayed when drilling in from multi-city list
struct CityDetailView: View {
    let city: CityData
    @Binding var navigationPath: NavigationPath

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
                    ForEach(city.lists) { list in
                        NavigationLink(value: list) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(list.name)
                                if let curator = list.curator {
                                    Text(curator.name)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.labelSecondary)
                                }
                            }
                        }
                        .listRowBackground(Color.backgroundGroupedSecondary)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("\(city.name), \(city.country)")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - List Detail View

struct ListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var list: CuratedListData
    @Binding var navigationPath: NavigationPath
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
            // Description & Curator Section (grouped together)
            if !list.listDescription.isEmpty || list.curator != nil {
                Section {
                    if !list.listDescription.isEmpty {
                        Text(list.listDescription)
                            .foregroundStyle(Color.labelSecondary)
                    }

                    if let curator = list.curator {
                        NavigationLink(value: curator) {
                            LabeledContent("Curator", value: curator.name)
                        }
                        .listRowBackground(Color.backgroundGroupedSecondary)
                    }
                }
            }

            // Spots Section
            Section("Spots") {
                if isLoadingSpots {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let error = spotsLoadError {
                    Text("Failed to load spots: \(error.localizedDescription)")
                        .foregroundStyle(Color.labelSecondary)
                } else if list.spots.isEmpty {
                    Text("No spots available")
                        .foregroundStyle(Color.labelSecondary)
                } else {
                    ForEach(list.spots) { spot in
                        Button {
                            selectedSpot = spot
                        } label: {
                            LabeledContent {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(Color.accentBlue)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(spot.name)
                                        .foregroundStyle(Color.labelPrimary)
                                    if !spot.category.isEmpty {
                                        Text(spot.category)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.labelSecondary)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
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
                        Image(systemName: "bell.slash")
                    }
                    .buttonBorderShape(.circle)
                } else {
                    Button {
                        activateList()
                    } label: {
                        Image(systemName: "bell")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .disabled(isLoadingSpots)
                }
            }
        }
        .alert("Notifications Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
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
            print("Failed to load spots: \(error)")
        }

        isLoadingSpots = false
    }

    // MARK: - Activation

    private func activateList() {
        isActivating = true
        Task {
            // Request location permission if not already requested
            if !PermissionService.shared.hasRequestedLocationPermissions {
                _ = await PermissionService.shared.requestLocationPermission()
            }

            // Request notification permission if not already requested
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
                // Already requested - verify notifications are enabled
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

            // Activate the list (spots should already be loaded)
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

// MARK: - Curator Detail View

struct CuratorDetailView: View {
    let curator: CuratorData
    @Binding var navigationPath: NavigationPath

    private var listsGroupedByCity: [(city: CityData?, lists: [CuratedListData])] {
        let grouped = Dictionary(grouping: curator.lists, by: { $0.city?.id })
        return grouped.map { (city: $0.value.first?.city, lists: $0.value.sorted { $0.name < $1.name }) }
            .sorted { ($0.city?.name ?? "") < ($1.city?.name ?? "") }
    }

    var body: some View {
        List {
            // Bio & Instagram Section
            if !curator.bio.isEmpty || curator.instagramHandle != nil {
                Section {
                    if !curator.bio.isEmpty {
                        Text(curator.bio)
                            .foregroundStyle(Color.labelSecondary)
                    }

                    if let instagram = curator.instagramHandle {
                        Button {
                            openInstagram(instagram)
                        } label: {
                            Text("Instagram")
                                .frame(maxWidth: .infinity)
                        }
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    }
                }
            }

            // Lists Section
            if !curator.lists.isEmpty {
                ForEach(listsGroupedByCity, id: \.city?.id) { group in
                    Section(group.city != nil ? "\(group.city!.name), \(group.city!.country)" : "Lists") {
                        ForEach(group.lists) { list in
                            NavigationLink(value: list) {
                                Text(list.name)
                            }
                            .listRowBackground(Color.backgroundGroupedSecondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(curator.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private func openInstagram(_ handle: String) {
        let cleanHandle = handle.replacingOccurrences(of: "@", with: "")
        if let url = URL(string: "https://instagram.com/\(cleanHandle)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Previews

#Preview("Empty") {
    CuratedListsView()
        .modelContainer(PreviewContainer.container)
}

#Preview("With Lists") {
    CuratedListsView()
        .modelContainer(PreviewContainer.containerWithData)
}
