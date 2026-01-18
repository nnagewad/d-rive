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
                } else {
                    listContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.backgroundGroupedPrimary)
            .sheet(isPresented: $showUpdatesSheet) {
                UpdatesSheetView()
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

    // MARK: - List Content

    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(cities) { city in
                    citySection(city)
                }
            }
            .padding(.top, Spacing.small)
        }
    }

    // MARK: - City Section

    private func citySection(_ city: CityData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CityHeader(city: city.name, country: city.country)

            if city.lists.isEmpty {
                GroupedCard {
                    InfoRow(label: "No lists available", value: "")
                }
                .padding(.horizontal, Spacing.medium)
            } else {
                GroupedCard {
                    VStack(spacing: 0) {
                        ForEach(Array(city.lists.enumerated()), id: \.element.id) { index, list in
                            if index > 0 {
                                RowSeparator()
                            }
                            DrillRow(
                                title: list.name,
                                subtitle: list.curator?.name ?? ""
                            ) {
                                navigationPath.append(list)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.medium)
            }
        }
        .padding(.bottom, Spacing.medium)
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
        .alert("Permissions Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable notifications and location access in Settings to receive alerts when you're near saved spots.")
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

        // Check if we've already requested permissions before
        if PermissionService.shared.hasRequestedPermissions {
            // Already requested - check if permissions are actually granted
            Task {
                await PermissionService.shared.refreshPermissionStatus()

                await MainActor.run {
                    if !PermissionService.shared.hasRequiredPermissions {
                        // Permissions not granted - show alert and turn toggle off
                        list.notifyWhenNearby = false
                        showPermissionAlert = true
                    }
                    saveAndReload()
                }
            }
            return
        }

        // First time enabling - request permissions
        isRequestingPermissions = true
        Task {
            let granted = await PermissionService.shared.requestPermissions()

            await MainActor.run {
                isRequestingPermissions = false

                if !granted {
                    // Permissions denied - turn the toggle back off
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

    var body: some View {
        VStack(spacing: 0) {
            NavigationHeader(title: "", onBack: { navigationPath.removeLast() })

            ScrollView {
                VStack(spacing: Spacing.medium) {
                    DetailTitle(title: curator.name)

                    if !curator.bio.isEmpty {
                        DescriptionCard(text: curator.bio)
                            .padding(.horizontal, Spacing.medium)
                    }

                    if let instagram = curator.instagramHandle {
                        GroupedCard {
                            LinkRow(label: "Instagram") {
                                openInstagram(instagram)
                            }
                        }
                        .padding(.horizontal, Spacing.medium)
                    }

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

    private var listsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "\(curator.name)'s lists", style: .prominent)

            GroupedCard {
                VStack(spacing: 0) {
                    ForEach(Array(curator.lists.enumerated()), id: \.element.id) { index, list in
                        if index > 0 {
                            RowSeparator()
                        }
                        DrillRow(
                            title: list.name,
                            subtitle: list.city?.name ?? ""
                        ) {
                            navigationPath.append(list)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.medium)
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
