import SwiftUI

// MARK: - Grouped Card

/// iOS-style grouped card container
/// Used for: Settings sections, info cards, list groups
struct GroupedCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color.backgroundGroupedSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }
}

// MARK: - Section Container

/// Section with optional header and footer
/// Used for: Grouping related rows with labels
struct SectionContainer<Content: View>: View {
    var header: String? = nil
    var footer: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let header {
                SectionHeader(title: header)
            }

            GroupedCard {
                content()
            }

            if let footer {
                SectionFooter(text: footer)
            }
        }
    }
}

// MARK: - Section Header

/// Section header text
/// Used for: "Curated spots", "Updates available"
struct SectionHeader: View {
    let title: String
    var style: SectionHeaderStyle = .standard

    enum SectionHeaderStyle {
        case standard   // Gray text, medium weight
        case prominent  // Larger, semibold
    }

    var body: some View {
        Text(title)
            .font(style == .standard ? .subheadlineRegular : .headlineRegular)
            .foregroundColor(Color.labelSecondary)
            .padding(.horizontal, Spacing.medium)
            .padding(.top, Spacing.small)
            .padding(.bottom, Spacing.xSmall)
    }
}

// MARK: - Section Footer

/// Section footer text
/// Used for: Explanatory text below cards
struct SectionFooter: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnoteRegular)
            .foregroundColor(Color.labelSecondary)
            .padding(.horizontal, Spacing.medium)
            .padding(.top, Spacing.xSmall)
            .padding(.bottom, Spacing.small)
    }
}

// MARK: - Description Card

/// Multi-line description card
/// Used for: Curator bio, curated list description
struct DescriptionCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.bodyRegular)
            .foregroundColor(Color.labelPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, 12)
            .background(Color.backgroundGroupedSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }
}

// MARK: - City Header

/// Subheader for city groupings
/// Used for: "[City], [Country]" in list views
struct CityHeader: View {
    let city: String
    let country: String

    var body: some View {
        Text("\(city), \(country)")
            .font(.subheadlineRegular)
            .foregroundColor(Color.labelSecondary)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.xSmall)
    }
}

// MARK: - List Section Title

/// Section title with separator line
/// Used for: "Closest first" in Nearby Spots
struct ListSectionTitle: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.separatorOpaque)
                .frame(height: 0.5)

            HStack {
                Text(title)
                    .font(.headlineRegular)
                    .foregroundColor(Color.labelSecondary)
                Spacer()
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
        }
    }
}

// MARK: - Previews

#Preview("Grouped Card") {
    VStack(spacing: 16) {
        GroupedCard {
            VStack(spacing: 0) {
                Text("Row 1")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                Divider()
                Text("Row 2")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
    }
    .padding()
    .background(Color.backgroundGroupedPrimary)
}

#Preview("Section Container") {
    ScrollView {
        VStack(spacing: 24) {
            SectionContainer(header: "Default Map App", footer: "Choose your preferred maps application.") {
                VStack(spacing: 0) {
                    Text("Apple Maps")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    Divider()
                    Text("Google Maps")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }

            SectionContainer(header: "Active Geofences") {
                Text("5 spots being monitored")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .padding()
    }
    .background(Color.backgroundGroupedPrimary)
}

#Preview("Description Card") {
    VStack(spacing: 16) {
        DescriptionCard(text: "A little bio about the curator. They love finding hidden gems in cities around the world.")
    }
    .padding()
    .background(Color.backgroundGroupedPrimary)
}

#Preview("Headers") {
    VStack(alignment: .leading, spacing: 16) {
        SectionHeader(title: "Updates available")
        SectionHeader(title: "Curated spots", style: .prominent)
        CityHeader(city: "Paris", country: "France")
        ListSectionTitle(title: "Closest first")
    }
    .background(Color.backgroundGroupedPrimary)
}
