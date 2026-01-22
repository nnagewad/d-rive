import SwiftUI

// MARK: - Drill Row

/// Navigation row with title, optional subtitle, optional value, and chevron
/// Used for: List items, settings navigation, curator lists
struct DrillRow: View {
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.bodyRegular)
                        .foregroundColor(Color.labelPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadlineRegular)
                            .foregroundColor(Color.labelSecondary)
                    }
                }

                Spacer()

                if let value {
                    Text(value)
                        .font(.bodyRegular)
                        .foregroundColor(Color.labelSecondary)
                        .padding(.trailing, Spacing.xSmall)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.labelTertiary)
            }
            .padding(.horizontal, Spacing.medium)
            .frame(minHeight: subtitle != nil ? RowHeight.withSubtitle : RowHeight.standard)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Info Row

/// Static information row with label and value
/// Used for: Category display, static info in detail views
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.bodyRegular)
                .foregroundColor(Color.labelPrimary)

            Spacer()

            Text(value)
                .font(.bodyRegular)
                .foregroundColor(Color.labelSecondary)
        }
        .padding(.horizontal, Spacing.medium)
        .frame(minHeight: RowHeight.standard)
    }
}

// MARK: - Link Row

/// Row with an action button (e.g., "Open" for external links)
/// Used for: Instagram, Website links in spot detail
struct LinkRow: View {
    let label: String
    var actionLabel: String = "Open"
    var action: () -> Void

    var body: some View {
        HStack {
            Text(label)
                .font(.bodyRegular)
                .foregroundColor(Color.labelPrimary)

            Spacer()

            Button(action: action) {
                Text(actionLabel)
                    .font(.bodyRegular)
                    .foregroundColor(Color.accentBlue)
            }
        }
        .padding(.horizontal, Spacing.medium)
        .frame(minHeight: RowHeight.standard)
    }
}

// MARK: - Toggle Row

/// Row with a toggle switch
/// Used for: "Notify When Nearby" setting
struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.bodyRegular)
                .foregroundColor(Color.labelPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, Spacing.medium)
        .frame(minHeight: RowHeight.standard)
    }
}

// MARK: - Selectable Row

/// Row with checkmark for single selection
/// Used for: Default Map App picker
struct SelectableRow: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.bodyRegular)
                    .foregroundColor(Color.labelPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.accentBlue)
                }
            }
            .padding(.horizontal, Spacing.medium)
            .frame(minHeight: RowHeight.standard)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Spot Row

/// Row for displaying a spot with title, category, and info/drill accessory
/// Used for: Nearby Spots list, Curated spots list
/// Design: 68px height, separator at top, 16px horizontal padding
struct SpotRow: View {
    let name: String
    let category: String
    var onInfoTapped: (() -> Void)? = nil
    var onRowTapped: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Separator at top of row
            Rectangle()
                .fill(Color.separatorVibrant)
                .frame(height: 0.5)

            HStack(spacing: 0) {
                Button(action: { onRowTapped?() }) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(name)
                            .font(.bodyRegular)
                            .foregroundColor(Color.labelPrimary)
                            .frame(height: 22)

                        Text(category)
                            .font(.subheadlineRegular)
                            .foregroundColor(Color.labelSecondary)
                            .frame(height: 20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if let onInfoTapped {
                    Button(action: onInfoTapped) {
                        Image(systemName: "info.circle")
                            .font(.system(size: IconSize.info))
                            .foregroundColor(Color.accentBlue)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.labelTertiary)
                        .frame(width: 8)
                }
            }
            .padding(.horizontal, Spacing.medium)
            .frame(height: RowHeight.withSubtitle - 0.5)
        }
        .frame(height: RowHeight.withSubtitle)
    }
}

// MARK: - Row Separator

/// Standard row separator
struct RowSeparator: View {
    var leadingPadding: CGFloat = Spacing.medium

    var body: some View {
        Rectangle()
            .fill(Color.separatorVibrant)
            .frame(height: 0.5)
            .padding(.leading, leadingPadding)
    }
}

// MARK: - Previews

#Preview("Drill Rows") {
    List {
        Section {
            DrillRow(title: "Simple Row") {}
            DrillRow(title: "With Value", value: "Apple Maps") {}
            DrillRow(title: "With Subtitle", subtitle: "Secondary text") {}
            DrillRow(title: "Full Row", subtitle: "With all options", value: "Value") {}
        }
    }
}

#Preview("Info & Link Rows") {
    List {
        Section {
            InfoRow(label: "Category", value: "Cafe")
            LinkRow(label: "Instagram") {}
            LinkRow(label: "Website", actionLabel: "Open") {}
        }
    }
}

#Preview("Toggle & Selectable") {
    struct PreviewWrapper: View {
        @State private var isOn = false
        var body: some View {
            List {
                Section {
                    ToggleRow(label: "Notify When Nearby", isOn: $isOn)
                }
                Section {
                    SelectableRow(title: "Ask Next Time", isSelected: true) {}
                    SelectableRow(title: "Apple Maps", isSelected: false) {}
                    SelectableRow(title: "Google Maps", isSelected: false) {}
                }
            }
        }
    }
    return PreviewWrapper()
}

#Preview("Spot Rows") {
    List {
        Section {
            SpotRow(name: "Café Lomi", category: "Coffee", onInfoTapped: {})
            SpotRow(name: "Le Comptoir Général", category: "Bar", onRowTapped: {})
        }
    }
}
