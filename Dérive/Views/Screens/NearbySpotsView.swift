import SwiftUI

// MARK: - Nearby Spots View

/// Main screen showing nearby spots from downloaded curated lists
/// Tab 1 in the app navigation
struct NearbySpotsView: View {
    @State private var spots: [Spot]
    @State private var isLoading: Bool

    init(spots: [Spot] = [], isLoading: Bool = false) {
        _spots = State(initialValue: spots)
        _isLoading = State(initialValue: isLoading)
    }

    var body: some View {
        VStack(spacing: 0) {
            LargeTitleHeader(title: "Nearby Spots")

            if isLoading {
                LoadingState(message: "Loading spots...")
            } else if spots.isEmpty {
                emptyState
            } else {
                spotsList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.backgroundGroupedPrimary)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyState(
            title: "No Nearby Spots",
            subtitle: "Add a Curated List"
        )
    }

    // MARK: - Spots List

    private var spotsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ListSectionTitle(title: "Closest first")

                ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
                    if index > 0 {
                        RowSeparator()
                    }
                    SpotRow(
                        name: spot.name,
                        category: spot.category,
                        onInfoTapped: {
                            // Show spot detail sheet
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Spot Model

struct Spot: Identifiable {
    let id: UUID
    let name: String
    let category: String
    var instagram: String?
    var website: String?
    var latitude: Double
    var longitude: Double

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        instagram: String? = nil,
        website: String? = nil,
        latitude: Double = 0,
        longitude: Double = 0
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.instagram = instagram
        self.website = website
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Previews

#Preview("Empty State") {
    NearbySpotsView()
}

#Preview("With Spots") {
    NearbySpotsView(spots: [
        Spot(name: "Café Lomi", category: "Coffee"),
        Spot(name: "Le Comptoir Général", category: "Bar"),
        Spot(name: "Shakespeare and Company", category: "Bookstore"),
        Spot(name: "Pink Mamma", category: "Restaurant"),
        Spot(name: "Le Marais Vintage", category: "Shopping")
    ])
}
