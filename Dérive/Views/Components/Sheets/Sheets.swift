import SwiftUI

// MARK: - Base Sheet

/// Base sheet container with drag handle and rounded corners
/// Used for: All modal sheets
struct BaseSheet<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.backgroundGroupedPrimary)
        .clipShape(
            RoundedCorner(radius: CornerRadius.large, corners: [.topLeft, .topRight])
        )
    }
}

// MARK: - Sheet With Header

/// Sheet with standard header (title + close button)
/// Used for: Updates sheet, spot detail sheet
struct SheetWithHeader<Content: View>: View {
    let title: String
    var onClose: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        BaseSheet {
            VStack(spacing: 0) {
                SheetHeader(title: title, onClose: onClose)
                content()
            }
        }
    }
}

// MARK: - Updates Sheet Content

/// Content wrapper for updates sheet states
/// Used for: Updates sheet (loading/empty/content states)
struct UpdatesSheetContent: View {
    let state: UpdatesState

    enum UpdatesState {
        case loading
        case empty
        case content(updates: [UpdateItem], history: [String])
    }

    struct UpdateItem: Identifiable {
        let id = UUID()
        let title: String
        var isUpdating: Bool = false
    }

    var onUpdateAll: (() -> Void)?
    var onUpdate: ((UpdateItem) -> Void)?

    var body: some View {
        switch state {
        case .loading:
            LoadingState(message: "Checking for updates")

        case .empty:
            EmptyState(title: "No updates available")

        case .content(let updates, let history):
            ScrollView {
                VStack(spacing: 0) {
                    if !updates.isEmpty {
                        updatesSection(updates)
                    }

                    if !history.isEmpty {
                        historySection(history)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func updatesSection(_ updates: [UpdateItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Updates available")

            GroupedCard {
                VStack(spacing: 0) {
                    UpdateAllRow(count: updates.count) {
                        onUpdateAll?()
                    }

                    ForEach(updates) { item in
                        RowSeparator()
                        UpdateRow(title: item.title, isUpdating: item.isUpdating) {
                            onUpdate?(item)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.medium)
        }
        .padding(.bottom, Spacing.medium)
    }

    @ViewBuilder
    private func historySection(_ history: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Recently updated")

            GroupedCard {
                VStack(spacing: 0) {
                    ForEach(Array(history.enumerated()), id: \.offset) { index, title in
                        if index > 0 {
                            RowSeparator()
                        }
                        HistoryRow(title: title)
                    }
                }
            }
            .padding(.horizontal, Spacing.medium)
        }
    }
}

// MARK: - Rounded Corner Helper

/// Helper shape for rounding specific corners
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Previews

#Preview("Base Sheet") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        BaseSheet {
            VStack {
                Text("Sheet Content")
                    .padding()
                Spacer()
            }
        }
        .frame(height: 400)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview("Sheet With Header") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        SheetWithHeader(title: "Updates", onClose: {}) {
            Text("Content goes here")
                .padding()
            Spacer()
        }
        .frame(height: 400)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview("Updates Sheet - Loading") {
    SheetWithHeader(title: "Updates", onClose: {}) {
        UpdatesSheetContent(state: .loading)
    }
    .frame(height: 500)
}

#Preview("Updates Sheet - Empty") {
    SheetWithHeader(title: "Updates", onClose: {}) {
        UpdatesSheetContent(state: .empty)
    }
    .frame(height: 500)
}

#Preview("Updates Sheet - Content") {
    SheetWithHeader(title: "Updates", onClose: {}) {
        UpdatesSheetContent(
            state: .content(
                updates: [
                    .init(title: "Paris Coffee Spots"),
                    .init(title: "Berlin Street Art"),
                    .init(title: "Tokyo Ramen Guide", isUpdating: true)
                ],
                history: [
                    "London Pubs",
                    "NYC Pizza",
                    "Barcelona Tapas"
                ]
            )
        )
    }
    .frame(height: 600)
}
