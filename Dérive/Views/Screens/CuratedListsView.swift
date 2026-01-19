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

    private var hasMultipleCities: Bool {
        cities.count > 1
    }

    private var citiesGroupedByCountry: [(country: String, cities: [CityData])] {
        let grouped = Dictionary(grouping: cities, by: { $0.country })
        return grouped.map { (country: $0.key, cities: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.country < $1.country }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                LargeTitleHeader(
                    title: "Curated Lists",
                    trailingButton: .init(title: "Updates") {
                        showUpdatesSheet = true
                    }
                )

                if cities.isEmpty {
                    emptyState
                } else if hasMultipleCities {
                    citiesListContent
                } else {
                    singleCityContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.backgroundGroupedPrimary)
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
        EmptyState(
            title: "No Curated Lists",
            subtitle: "Browse and download lists to get started"
        )
    }

    // MARK: - Cities List Content (Multiple Cities)

    private var citiesListContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(citiesGroupedByCountry, id: \.country) { group in
                    countrySection(country: group.country, cities: group.cities)
                }
            }
            .padding(.top, Spacing.small)
        }
    }

    private func countrySection(country: String, cities: [CityData]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CountryHeader(country: country)

            ForEach(cities) { city in
                RowSeparator()
                DrillRow(title: city.name) {
                    navigationPath.append(city)
                }
            }
        }
    }

    // MARK: - Single City Content

    private var singleCityContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(cities) { city in
                    citySection(city)
                }
            }
            .padding(.top, Spacing.small)
        }
    }

    private func citySection(_ city: CityData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            RowSeparator(leadingPadding: 0)
            CityHeader(city: city.name, country: city.country)

            if city.lists.isEmpty {
                EmptyState(
                    title: "No Lists",
                    subtitle: "No curated lists available for this city"
                )
            } else {
                ForEach(city.lists) { list in
                    RowSeparator(leadingPadding: 0)
                    DrillRow(
                        title: list.name,
                        subtitle: list.curator?.name ?? ""
                    ) {
                        navigationPath.append(list)
                    }
                }
            }
        }
    }
}

// MARK: - City Detail View

/// Detail view showing curated lists for a specific city
/// Displayed when drilling in from multi-city list
struct CityDetailView: View {
    let city: CityData
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 0) {
            NavigationHeader(title: "", onBack: { navigationPath.removeLast() })

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    DetailTitle(title: "\(city.name), \(city.country)")
                        .padding(.bottom, Spacing.medium)

                    if city.lists.isEmpty {
                        EmptyState(
                            title: "No Lists",
                            subtitle: "No curated lists available for this city"
                        )
                    } else {
                        ForEach(city.lists) { list in
                            RowSeparator(leadingPadding: 0)
                            DrillRow(
                                title: list.name,
                                subtitle: list.curator?.name ?? ""
                            ) {
                                navigationPath.append(list)
                            }
                        }
                    }
                }
                .padding(.top, Spacing.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.backgroundGroupedPrimary)
        .navigationBarHidden(true)
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
    @State private var selectedSpot: SpotData?

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: Spacing.medium) {
                    infoSection
                    actionSection
                    if list.isDownloaded {
                        spotsSection
                    }
                }
                .padding(.top, Spacing.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.backgroundGroupedPrimary)
        .navigationBarHidden(true)
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

    // MARK: - Header

    private var header: some View {
        NavigationHeader(title: "", onBack: { navigationPath.removeLast() })
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            DetailTitle(title: list.name)

            if !list.listDescription.isEmpty {
                DescriptionCard(text: list.listDescription)
                    .padding(.horizontal, Spacing.medium)
            }

            if let curator = list.curator {
                GroupedCard {
                    DrillRow(
                        title: "Curator",
                        value: curator.name
                    ) {
                        navigationPath.append(curator)
                    }
                }
                .padding(.horizontal, Spacing.medium)
            }
        }
    }

    // MARK: - Action Section

    @ViewBuilder
    private var actionSection: some View {
        if list.isDownloaded {
            GroupedCard {
                ToggleRow(label: "Notify When Nearby", isOn: $list.notifyWhenNearby)
            }
            .padding(.horizontal, Spacing.medium)
            .onChange(of: list.notifyWhenNearby) { oldValue, newValue in
                handleNotifyToggleChange(from: oldValue, to: newValue)
            }
        } else {
            PrimaryButton(
                title: isDownloading ? "" : "Download",
                isLoading: isDownloading
            ) {
                downloadList()
            }
            .padding(.horizontal, Spacing.medium)
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

    // MARK: - Spots Section

    private var spotsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Spots", style: .prominent)

            GroupedCard {
                VStack(spacing: 0) {
                    ForEach(Array(list.spots.enumerated()), id: \.element.id) { index, spot in
                        if index > 0 {
                            RowSeparator()
                        }
                        SpotRow(
                            name: spot.name,
                            category: spot.category,
                            onInfoTapped: {
                                selectedSpot = spot
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, Spacing.medium)
        }
    }

    // MARK: - Actions

    private func downloadList() {
        isDownloading = true
        Task {
            // Request location permission on first download
            if !PermissionService.shared.hasRequestedLocationPermissions {
                _ = await PermissionService.shared.requestLocationPermission()
            }

            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                list.isDownloaded = true
                list.lastUpdated = .now
                isDownloading = false
                reloadGeofences()
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
        VStack(spacing: 0) {
            NavigationHeader(title: "", onBack: { navigationPath.removeLast() })

            ScrollView {
                VStack(spacing: Spacing.medium) {
                    DetailTitle(title: curator.name)

                    infoCard

                    if !curator.lists.isEmpty {
                        listsSection
                    }
                }
                .padding(.top, Spacing.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.backgroundGroupedPrimary)
        .navigationBarHidden(true)
    }

    // MARK: - Info Card (Bio + Instagram)

    @ViewBuilder
    private var infoCard: some View {
        let hasBio = !curator.bio.isEmpty
        let hasInstagram = curator.instagramHandle != nil

        if hasBio || hasInstagram {
            GroupedCard {
                VStack(spacing: 0) {
                    if hasBio {
                        Text(curator.bio)
                            .font(.bodyRegular)
                            .foregroundColor(Color.labelPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.medium)
                            .padding(.vertical, 12)
                    }

                    if hasBio && hasInstagram {
                        RowSeparator(leadingPadding: 0)
                    }

                    if let instagram = curator.instagramHandle {
                        LinkRow(label: "Instagram") {
                            openInstagram(instagram)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.medium)
        }
    }

    // MARK: - Lists Section

    private var listsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "\(curator.name) curated lists", style: .prominent)

            ForEach(listsGroupedByCity, id: \.city?.id) { group in
                if let city = group.city {
                    CityHeader(city: city.name, country: city.country)
                }

                ForEach(group.lists) { list in
                    RowSeparator(leadingPadding: 0)
                    DrillRow(title: list.name) {
                        navigationPath.append(list)
                    }
                }
            }
        }
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
