import SwiftUI

// MARK: - Individual Curated List View

/// Detail view for a single curated list
/// Shows download state, description, curator, and spots
struct IndividualCuratedListView: View {
    let list: CuratedList
    var onBack: () -> Void
    var onCuratorTapped: ((String) -> Void)?
    var onSpotTapped: ((Spot) -> Void)?

    @State private var isDownloading: Bool = false
    @State private var notifyWhenNearby: Bool = false

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
        .onAppear {
            notifyWhenNearby = list.notifyWhenNearby
        }
    }

    // MARK: - Header

    private var header: some View {
        NavigationHeader(title: "", onBack: onBack) {
            if list.isDownloaded {
                if list.hasUpdate {
                    PillButton(title: "Update") {
                        // Update list
                    }
                } else {
                    IconButton(systemName: "circle", style: .filled) {
                        // Subscribed indicator
                    }
                }
            }
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            DetailTitle(title: list.name)

            DescriptionCard(text: list.description.isEmpty ? "A curated list of amazing spots." : list.description)
                .padding(.horizontal, Spacing.medium)

            GroupedCard {
                DrillRow(
                    title: "Curator",
                    value: list.curatorName
                ) {
                    onCuratorTapped?(list.curatorName)
                }
            }
            .padding(.horizontal, Spacing.medium)
        }
    }

    // MARK: - Action Section

    @ViewBuilder
    private var actionSection: some View {
        if list.isDownloaded {
            GroupedCard {
                ToggleRow(label: "Notify When Nearby", isOn: $notifyWhenNearby)
            }
            .padding(.horizontal, Spacing.medium)
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

    // MARK: - Spots Section

    private var spotsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Curated spots", style: .prominent)

            GroupedCard {
                VStack(spacing: 0) {
                    ForEach(Array(list.spots.enumerated()), id: \.element.id) { index, spot in
                        if index > 0 {
                            RowSeparator()
                        }
                        SpotRow(
                            name: spot.name,
                            category: spot.category,
                            onRowTapped: {
                                onSpotTapped?(spot)
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
        // Simulate download
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isDownloading = false
        }
    }
}

// MARK: - Previews

#Preview("Not Downloaded") {
    IndividualCuratedListView(
        list: CuratedList(
            name: "Paris Coffee Spots",
            curatorName: "Marie",
            description: "The best coffee spots in Paris, from hidden gems to classic cafés.",
            isDownloaded: false
        ),
        onBack: {}
    )
}

#Preview("Downloaded") {
    IndividualCuratedListView(
        list: CuratedList(
            name: "Paris Coffee Spots",
            curatorName: "Marie",
            description: "The best coffee spots in Paris, from hidden gems to classic cafés.",
            isDownloaded: true,
            spots: [
                Spot(name: "Café Lomi", category: "Coffee"),
                Spot(name: "Coutume Café", category: "Coffee"),
                Spot(name: "Boot Café", category: "Coffee"),
                Spot(name: "Telescope", category: "Coffee"),
                Spot(name: "Ten Belles", category: "Coffee"),
            ]
        ),
        onBack: {}
    )
}

#Preview("With Update") {
    IndividualCuratedListView(
        list: CuratedList(
            name: "Paris Coffee Spots",
            curatorName: "Marie",
            description: "The best coffee spots in Paris.",
            isDownloaded: true,
            hasUpdate: true,
            spots: [
                Spot(name: "Café Lomi", category: "Coffee"),
                Spot(name: "Coutume Café", category: "Coffee"),
            ]
        ),
        onBack: {}
    )
}
