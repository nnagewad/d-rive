import SwiftUI

// MARK: - Large Title Header

/// Screen header with large title and optional trailing button
/// Used for: Main screens (Nearby Spots, Curated Lists, Settings)
/// Design: SF Pro Bold 34pt, vibrant primary color, liquid glass button
struct LargeTitleHeader: View {
    let title: String
    var trailingButton: TrailingButton? = nil

    struct TrailingButton {
        let title: String
        let action: () -> Void
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Spacer()
                if let button = trailingButton {
                    PillButton(title: button.title, style: .glass) {
                        button.action()
                    }
                }
            }
            .frame(height: 44)

            Text(title)
                .font(.largeTitleEmphasized)
                .foregroundColor(Color.labelVibrantPrimary)
                .tracking(0.4)
        }
        .padding(.horizontal, Spacing.medium)
    }
}

// MARK: - Navigation Header

/// Header with back button, inline title, and optional trailing content
/// Used for: Detail screens with push navigation
struct NavigationHeader<Trailing: View>: View {
    let title: String
    var onBack: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    init(
        title: String,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.onBack = onBack
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 0) {
            BackButton(action: onBack)

            Spacer()

            trailing()
        }
        .frame(height: 44)
        .padding(.horizontal, Spacing.xSmall)
    }
}

// MARK: - Detail Title

/// Large title for detail screens (below navigation header)
/// Used for: Curated list name, Curator name, Spot name
struct DetailTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.largeTitleEmphasized)
            .foregroundColor(Color.labelPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
    }
}

// MARK: - Sheet Header

/// Header for modal sheets with title and close button
/// Used for: Updates sheet, Individual spot sheet
struct SheetHeader: View {
    let title: String
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.labelTertiary)
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 8)

            HStack {
                Text(title)
                    .font(.headlineRegular)
                    .foregroundColor(Color.labelPrimary)

                Spacer()

                CloseButton(action: onClose)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.bottom, Spacing.small)
        }
    }
}

// MARK: - Curator Header

/// Header showing curator's lists section
/// Used for: "[Curator's name] curated lists"
struct CuratorListsHeader: View {
    let curatorName: String

    var body: some View {
        Text("\(curatorName) curated lists")
            .font(.headlineRegular)
            .foregroundColor(Color.labelPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
    }
}

// MARK: - Previews

#Preview("Large Title Header") {
    VStack(spacing: 24) {
        LargeTitleHeader(title: "Nearby Spots")

        LargeTitleHeader(
            title: "Curated Lists",
            trailingButton: .init(title: "Updates") {}
        )
    }
    .background(Color.backgroundGroupedPrimary)
}

#Preview("Navigation Header") {
    VStack(spacing: 24) {
        NavigationHeader(title: "Detail", onBack: {})

        NavigationHeader(title: "With Action", onBack: {}) {
            PillButton(title: "Update") {}
        }

        NavigationHeader(title: "With Icon", onBack: {}) {
            IconButton(systemName: "circle", style: .filled) {}
        }
    }
    .background(Color.backgroundGroupedPrimary)
}

#Preview("Detail Title") {
    VStack(alignment: .leading, spacing: 16) {
        NavigationHeader(title: "", onBack: {})
        DetailTitle(title: "Paris Coffee Spots")
    }
    .background(Color.backgroundGroupedPrimary)
}

#Preview("Sheet Header") {
    VStack {
        SheetHeader(title: "Updates", onClose: {})
        Spacer()
    }
    .background(Color.backgroundGroupedPrimary)
}

#Preview("Curator Header") {
    VStack {
        CuratorListsHeader(curatorName: "John's")
    }
    .background(Color.backgroundGroupedPrimary)
}
