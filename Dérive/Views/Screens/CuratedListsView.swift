import SwiftUI
import SwiftData
import UIKit

// MARK: - Curated Lists View

/// Main screen showing all available curated lists grouped by city
/// Tab 2 in the app navigation
struct CuratedListsView: View {
    @Query(sort: \CityData.name) private var cities: [CityData]
    @State private var showUpdatesSheet: Bool = false
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Updates") {
                        showUpdatesSheet = true
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
            }
            .sheet(isPresented: $showUpdatesSheet) {
                UpdatesSheetView()
            }
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
    @State private var showUpdatesSheet = false

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
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("\(city.name), \(city.country)")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Updates") {
                    showUpdatesSheet = true
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }
        }
        .sheet(isPresented: $showUpdatesSheet) {
            UpdatesSheetView()
        }
    }
}

// MARK: - List Detail View

struct ListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var list: CuratedListData
    @Binding var navigationPath: NavigationPath
    @State private var isDownloading = false
    @State private var isRequestingPermissions = false
    @State private var showPermissionAlert = false
    @State private var showUpdatesSheet = false
    @State private var selectedSpot: SpotData?

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
                    }
                }
            }

            // Action Section
            if list.isDownloaded {
                Section {
                    Toggle("Notify When Nearby", isOn: $list.notifyWhenNearby)
                        .onChange(of: list.notifyWhenNearby) { oldValue, newValue in
                            handleNotifyToggleChange(from: oldValue, to: newValue)
                        }
                } footer: {
                    Text("A notification banner appears when you're close to any of the spots on the list.")
                }
            } else {
                Section {
                    Button {
                        downloadList()
                    } label: {
                        HStack {
                            Spacer()
                            if isDownloading {
                                ProgressView()
                            } else {
                                Text("Download")
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .listRowBackground(Color.clear)
                    .disabled(isDownloading)
                }
            }

            // Spots Section
            if list.isDownloaded && !list.spots.isEmpty {
                Section("Spots") {
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Updates") {
                    showUpdatesSheet = true
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
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
        .sheet(isPresented: $showUpdatesSheet) {
            UpdatesSheetView()
        }
    }

    private func handleNotifyToggleChange(from oldValue: Bool, to newValue: Bool) {
        // Only check permissions when turning ON
        guard newValue == true else {
            saveAndReload()
            return
        }

        // Check if we've already requested notification permissions before
        if PermissionService.shared.hasRequestedNotificationPermissions {
            // Already requested - check if notification permission is actually granted
            Task {
                await PermissionService.shared.refreshPermissionStatus()

                await MainActor.run {
                    let hasNotifications = PermissionService.shared.notificationStatus == .authorized ||
                                          PermissionService.shared.notificationStatus == .provisional
                    if !hasNotifications {
                        // Notification permission not granted - show alert and turn toggle off
                        list.notifyWhenNearby = false
                        showPermissionAlert = true
                    }
                    saveAndReload()
                }
            }
            return
        }

        // First time enabling - request notification permission only
        isRequestingPermissions = true
        Task {
            let granted = await PermissionService.shared.requestNotificationPermission()

            await MainActor.run {
                isRequestingPermissions = false

                if !granted {
                    // Notification permission denied - turn the toggle back off
                    list.notifyWhenNearby = false
                }

                saveAndReload()
            }
        }
    }

    private func saveAndReload() {
        try? modelContext.save()
        reloadGeofences()
    }

    // MARK: - Actions

    private func downloadList() {
        isDownloading = true
        Task {
            // Request location permission on first download
            if !PermissionService.shared.hasRequestedLocationPermissions {
                _ = await PermissionService.shared.requestLocationPermission()
            }

            do {
                try await DataService.shared.downloadListFromSupabase(list)
                await MainActor.run {
                    isDownloading = false
                    reloadGeofences()
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                }
                print("Failed to download list: \(error)")
            }
        }
    }
}

// MARK: - Notification Toggle Observer

extension ListDetailView {
    /// Observes notification toggle changes and reloads geofences
    private func observeNotificationToggle() {
        // SwiftData automatically persists changes via @Bindable
        // We need to reload geofences when this changes
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
                            HStack {
                                Spacer()
                                Text("Instagram")
                                Spacer()
                            }
                        }
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
