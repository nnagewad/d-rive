import SwiftUI

// MARK: - Individual Spot View (Push Navigation)

/// Detail view for a single spot with push navigation style
struct IndividualSpotView: View {
    let spot: Spot
    var onBack: () -> Void
    var onGetDirections: (() -> Void)?
    var onOpenInstagram: (() -> Void)?
    var onOpenWebsite: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            NavigationHeader(title: "", onBack: onBack)

            ScrollView {
                VStack(spacing: Spacing.medium) {
                    DetailTitle(title: spot.name)

                    infoCard

                    PrimaryButton(title: "Get Directions") {
                        onGetDirections?()
                    }
                    .padding(.horizontal, Spacing.medium)
                }
                .padding(.top, Spacing.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.backgroundGroupedPrimary)
    }

    private var infoCard: some View {
        GroupedCard {
            VStack(spacing: 0) {
                InfoRow(label: "Category", value: spot.category)

                if spot.instagram != nil {
                    RowSeparator()
                    LinkRow(label: "Instagram") {
                        onOpenInstagram?()
                    }
                }

                if spot.website != nil {
                    RowSeparator()
                    LinkRow(label: "Website") {
                        onOpenWebsite?()
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.medium)
    }
}

// MARK: - Individual Spot Sheet View

/// Detail view for a single spot with sheet presentation style
struct IndividualSpotSheetView: View {
    let spot: Spot
    var onClose: () -> Void
    var onGetDirections: (() -> Void)?
    var onOpenInstagram: (() -> Void)?
    var onOpenWebsite: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: spot.name, onClose: onClose)

            ScrollView {
                VStack(spacing: Spacing.medium) {
                    infoCard

                    PrimaryButton(title: "Get Directions") {
                        onGetDirections?()
                    }
                    .padding(.horizontal, Spacing.medium)
                }
                .padding(.top, Spacing.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.backgroundGroupedPrimary)
    }

    private var infoCard: some View {
        GroupedCard {
            VStack(spacing: 0) {
                InfoRow(label: "Category", value: spot.category)

                if spot.instagram != nil {
                    RowSeparator()
                    LinkRow(label: "Instagram") {
                        onOpenInstagram?()
                    }
                }

                if spot.website != nil {
                    RowSeparator()
                    LinkRow(label: "Website") {
                        onOpenWebsite?()
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.medium)
    }
}

// MARK: - Previews

#Preview("Push Navigation") {
    IndividualSpotView(
        spot: Spot(
            name: "Café Lomi",
            category: "Coffee",
            instagram: "@cafelomi",
            website: "https://cafelomi.com"
        ),
        onBack: {}
    )
}

#Preview("Push - Minimal Info") {
    IndividualSpotView(
        spot: Spot(
            name: "Hidden Bar",
            category: "Bar"
        ),
        onBack: {}
    )
}

#Preview("Sheet Presentation") {
    IndividualSpotSheetView(
        spot: Spot(
            name: "Café Lomi",
            category: "Coffee",
            instagram: "@cafelomi",
            website: "https://cafelomi.com"
        ),
        onClose: {}
    )
}
