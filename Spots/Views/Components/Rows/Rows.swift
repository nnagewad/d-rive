//
//  Rows.swift
//  Purpose: Reusable row components (drill, info, link, toggle, selectable, spot)
//  Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-16.
//

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
                        .font(.body)
                        .foregroundStyle(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let value {
                    Text(value)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, Spacing.xSmall)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
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
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
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
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()

            Button(action: action) {
                Text(actionLabel)
                    .font(.body)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
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
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
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
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
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

/// Row for displaying a spot with name and category
/// Used for: Nearby Spots list, Curated spots list
struct SpotRow: View {
    let name: String
    let category: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .foregroundStyle(Color.accentColor)
                if !category.isEmpty {
                    Text(category)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
            SpotRow(name: "Café Lomi", category: "Coffee") {}
            SpotRow(name: "Le Comptoir Général", category: "Bar") {}
            SpotRow(name: "No Category Spot", category: "") {}
        }
    }
}
