import SwiftUI

// MARK: - Curated Lists View

/// Main screen showing all available curated lists grouped by city
/// Tab 2 in the app navigation
struct CuratedListsView: View {
    @State private var cities: [CityWithLists]
    @State private var showUpdatesSheet: Bool = false
    @State private var selectedCity: CityWithLists?

    init(cities: [CityWithLists] = []) {
        _cities = State(initialValue: cities)
    }

    var body: some View {
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
                // Current city section (if available)
                if let currentCity = cities.first {
                    currentCitySection(currentCity)
                }

                // Other cities
                if cities.count > 1 {
                    otherCitiesSection
                }
            }
            .padding(.top, Spacing.small)
        }
    }

    // MARK: - Current City Section

    private func currentCitySection(_ city: CityWithLists) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CityHeader(city: city.city, country: city.country)

            GroupedCard {
                VStack(spacing: 0) {
                    ForEach(Array(city.lists.enumerated()), id: \.element.id) { index, list in
                        if index > 0 {
                            RowSeparator()
                        }
                        DrillRow(
                            title: list.name,
                            subtitle: list.curatorName
                        ) {
                            // Navigate to individual list
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.medium)
        }
    }

    // MARK: - Other Cities Section

    private var otherCitiesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(cities.dropFirst().enumerated()), id: \.element.id) { countryIndex, country in
                SectionHeader(title: country.country)

                GroupedCard {
                    VStack(spacing: 0) {
                        ForEach(Array(uniqueCities(in: country).enumerated()), id: \.element) { cityIndex, cityName in
                            if cityIndex > 0 {
                                RowSeparator()
                            }
                            DrillRow(title: cityName) {
                                // Navigate to city detail
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.medium)
            }
        }
        .padding(.top, Spacing.medium)
    }

    private func uniqueCities(in cityWithLists: CityWithLists) -> [String] {
        [cityWithLists.city]
    }
}

// MARK: - City Detail View

/// Shows all curated lists for a specific city
struct CityDetailView: View {
    let city: String
    let country: String
    let lists: [CuratedList]
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            NavigationHeader(title: "", onBack: onBack)

            DetailTitle(title: "\(city), \(country)")

            ScrollView {
                LazyVStack(spacing: 0) {
                    GroupedCard {
                        VStack(spacing: 0) {
                            ForEach(Array(lists.enumerated()), id: \.element.id) { index, list in
                                if index > 0 {
                                    RowSeparator()
                                }
                                DrillRow(
                                    title: list.name,
                                    subtitle: list.curatorName
                                ) {
                                    // Navigate to individual list
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.medium)
                }
                .padding(.top, Spacing.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.backgroundGroupedPrimary)
    }
}

// MARK: - Models

struct CityWithLists: Identifiable {
    let id: UUID
    let city: String
    let country: String
    let lists: [CuratedList]

    init(id: UUID = UUID(), city: String, country: String, lists: [CuratedList]) {
        self.id = id
        self.city = city
        self.country = country
        self.lists = lists
    }
}

struct CuratedList: Identifiable {
    let id: UUID
    let name: String
    let curatorName: String
    let description: String
    var isDownloaded: Bool
    var hasUpdate: Bool
    var notifyWhenNearby: Bool
    var spots: [Spot]

    init(
        id: UUID = UUID(),
        name: String,
        curatorName: String,
        description: String = "",
        isDownloaded: Bool = false,
        hasUpdate: Bool = false,
        notifyWhenNearby: Bool = false,
        spots: [Spot] = []
    ) {
        self.id = id
        self.name = name
        self.curatorName = curatorName
        self.description = description
        self.isDownloaded = isDownloaded
        self.hasUpdate = hasUpdate
        self.notifyWhenNearby = notifyWhenNearby
        self.spots = spots
    }
}

// MARK: - Previews

#Preview("Empty") {
    CuratedListsView()
}

#Preview("With Lists") {
    CuratedListsView(cities: [
        CityWithLists(
            city: "Paris",
            country: "France",
            lists: [
                CuratedList(name: "Coffee Spots", curatorName: "Marie"),
                CuratedList(name: "Hidden Bars", curatorName: "Jean"),
                CuratedList(name: "Best Croissants", curatorName: "Pierre"),
            ]
        )
    ])
}

#Preview("City Detail") {
    CityDetailView(
        city: "Paris",
        country: "France",
        lists: [
            CuratedList(name: "Coffee Spots", curatorName: "Marie"),
            CuratedList(name: "Hidden Bars", curatorName: "Jean"),
        ],
        onBack: {}
    )
}
