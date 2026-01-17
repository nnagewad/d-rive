import SwiftUI

// MARK: - New Default Map App View

/// Picker for selecting the default map application
struct NewDefaultMapAppView: View {
    @State private var selectedOption: MapAppOption
    var onBack: () -> Void
    var onSelectionChanged: ((MapAppOption) -> Void)?

    init(
        selectedOption: MapAppOption = .askNextTime,
        onBack: @escaping () -> Void,
        onSelectionChanged: ((MapAppOption) -> Void)? = nil
    ) {
        _selectedOption = State(initialValue: selectedOption)
        self.onBack = onBack
        self.onSelectionChanged = onSelectionChanged
    }

    var body: some View {
        VStack(spacing: 0) {
            NavigationHeader(title: "Default Map App", onBack: onBack)

            ScrollView {
                VStack(spacing: 0) {
                    optionsSection
                }
                .padding(.top, Spacing.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.backgroundGroupedPrimary)
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            GroupedCard {
                VStack(spacing: 0) {
                    ForEach(MapAppOption.allCases) { option in
                        if option != .askNextTime {
                            RowSeparator()
                        }
                        SelectableRow(
                            title: option.title,
                            isSelected: selectedOption == option
                        ) {
                            selectedOption = option
                            onSelectionChanged?(option)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.medium)

            SectionFooter(text: "When set, selecting the notification will open your preferred map app.")
        }
    }
}

// MARK: - Map App Option

enum MapAppOption: String, CaseIterable, Identifiable {
    case askNextTime
    case appleMaps
    case googleMaps

    var id: String { rawValue }

    var title: String {
        switch self {
        case .askNextTime: return "Ask Next Time"
        case .appleMaps: return "Apple Maps"
        case .googleMaps: return "Google Maps"
        }
    }
}

// MARK: - Previews

#Preview("Default Map App") {
    NewDefaultMapAppView(onBack: {})
}

#Preview("Google Maps Selected") {
    NewDefaultMapAppView(
        selectedOption: .googleMaps,
        onBack: {}
    )
}
