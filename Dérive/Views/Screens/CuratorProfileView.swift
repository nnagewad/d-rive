import SwiftUI

// MARK: - Curator Profile View

/// Shows a curator's profile with bio and their curated lists
struct CuratorProfileView: View {
    let curator: Curator
    var onBack: () -> Void
    var onListTapped: ((CuratorList) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            NavigationHeader(title: "", onBack: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    // Curator Name
                    DetailTitle(title: curator.name)

                    // Bio
                    DescriptionCard(text: curator.bio)
                        .padding(.horizontal, Spacing.medium)

                    // Lists Section
                    listsSection
                }
                .padding(.top, Spacing.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.backgroundGroupedPrimary)
    }

    // MARK: - Lists Section

    private var listsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            CuratorListsHeader(curatorName: "\(curator.name)'s")

            ForEach(groupedListsByCity, id: \.city) { group in
                cityListsGroup(group)
            }
        }
    }

    private func cityListsGroup(_ group: CityListGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CityHeader(city: group.city, country: group.country)

            GroupedCard {
                VStack(spacing: 0) {
                    ForEach(Array(group.lists.enumerated()), id: \.element.id) { index, list in
                        if index > 0 {
                            RowSeparator()
                        }
                        DrillRow(title: list.name) {
                            onListTapped?(list)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.medium)
        }
        .padding(.bottom, Spacing.small)
    }

    // MARK: - Helpers

    private var groupedListsByCity: [CityListGroup] {
        var groups: [String: CityListGroup] = [:]

        for list in curator.lists {
            let key = "\(list.city)-\(list.country)"
            if var group = groups[key] {
                group.lists.append(list)
                groups[key] = group
            } else {
                groups[key] = CityListGroup(
                    city: list.city,
                    country: list.country,
                    lists: [list]
                )
            }
        }

        return Array(groups.values).sorted { $0.city < $1.city }
    }
}

// MARK: - Supporting Types

struct Curator: Identifiable {
    let id: UUID
    let name: String
    let bio: String
    let lists: [CuratorList]

    init(id: UUID = UUID(), name: String, bio: String, lists: [CuratorList] = []) {
        self.id = id
        self.name = name
        self.bio = bio
        self.lists = lists
    }
}

struct CuratorList: Identifiable {
    let id: UUID
    let name: String
    let city: String
    let country: String

    init(id: UUID = UUID(), name: String, city: String, country: String) {
        self.id = id
        self.name = name
        self.city = city
        self.country = country
    }
}

private struct CityListGroup {
    let city: String
    let country: String
    var lists: [CuratorList]
}

// MARK: - Previews

#Preview("Single City") {
    CuratorProfileView(
        curator: Curator(
            name: "Marie",
            bio: "A little bio about the curator. She loves finding hidden gems in cities around the world.",
            lists: [
                CuratorList(name: "Coffee Spots", city: "Paris", country: "France"),
                CuratorList(name: "Hidden Bars", city: "Paris", country: "France"),
                CuratorList(name: "Best Croissants", city: "Paris", country: "France"),
            ]
        ),
        onBack: {}
    )
}

#Preview("Multiple Cities") {
    CuratorProfileView(
        curator: Curator(
            name: "Jean",
            bio: "Travel enthusiast and food lover. Always looking for the best local spots.",
            lists: [
                CuratorList(name: "Coffee Spots", city: "Paris", country: "France"),
                CuratorList(name: "Wine Bars", city: "Paris", country: "France"),
                CuratorList(name: "Craft Beer", city: "Berlin", country: "Germany"),
                CuratorList(name: "Street Art", city: "Berlin", country: "Germany"),
                CuratorList(name: "Ramen Guide", city: "Tokyo", country: "Japan"),
            ]
        ),
        onBack: {}
    )
}
