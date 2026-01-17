import SwiftUI

// MARK: - Updates Sheet View

/// Sheet showing available updates for downloaded curated lists
struct UpdatesSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var state: UpdatesState
    @State private var updates: [ListUpdate]
    @State private var history: [String]

    init(
        state: UpdatesState = .loading,
        updates: [ListUpdate] = [],
        history: [String] = []
    ) {
        _state = State(initialValue: state)
        _updates = State(initialValue: updates)
        _history = State(initialValue: history)
    }

    var body: some View {
        SheetWithHeader(title: "Updates", onClose: { dismiss() }) {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            LoadingState(message: "Checking for updates")

        case .empty:
            EmptyState(title: "No updates available")

        case .content:
            ScrollView {
                VStack(spacing: 0) {
                    if !updates.isEmpty {
                        updatesSection
                    }

                    if !history.isEmpty {
                        historySection
                    }
                }
            }
        }
    }

    // MARK: - Updates Section

    private var updatesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Updates available")

            GroupedCard {
                VStack(spacing: 0) {
                    UpdateAllRow(count: updates.count) {
                        updateAll()
                    }

                    ForEach(Array(updates.enumerated()), id: \.element.id) { index, update in
                        RowSeparator()
                        UpdateRow(
                            title: update.listName,
                            isUpdating: update.isUpdating
                        ) {
                            updateList(update)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.medium)
        }
        .padding(.bottom, Spacing.medium)
    }

    // MARK: - History Section

    private var historySection: some View {
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

    // MARK: - Actions

    private func updateAll() {
        for i in updates.indices {
            updates[i].isUpdating = true
        }
        // Simulate update
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let updatedNames = updates.map { $0.listName }
            history.insert(contentsOf: updatedNames, at: 0)
            updates.removeAll()
            if updates.isEmpty && history.isEmpty {
                state = .empty
            }
        }
    }

    private func updateList(_ update: ListUpdate) {
        guard let index = updates.firstIndex(where: { $0.id == update.id }) else { return }
        updates[index].isUpdating = true

        // Simulate update
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            history.insert(update.listName, at: 0)
            updates.remove(at: index)
            if updates.isEmpty {
                state = history.isEmpty ? .empty : .content
            }
        }
    }
}

// MARK: - Supporting Types

enum UpdatesState {
    case loading
    case empty
    case content
}

struct ListUpdate: Identifiable {
    let id: UUID
    let listName: String
    var isUpdating: Bool

    init(id: UUID = UUID(), listName: String, isUpdating: Bool = false) {
        self.id = id
        self.listName = listName
        self.isUpdating = isUpdating
    }
}

// MARK: - Previews

#Preview("Loading") {
    UpdatesSheetView(state: .loading)
}

#Preview("Empty") {
    UpdatesSheetView(state: .empty)
}

#Preview("With Updates") {
    UpdatesSheetView(
        state: .content,
        updates: [
            ListUpdate(listName: "Paris Coffee Spots"),
            ListUpdate(listName: "Berlin Street Art"),
            ListUpdate(listName: "Tokyo Ramen Guide"),
        ],
        history: [
            "London Pubs",
            "NYC Pizza",
        ]
    )
}

#Preview("History Only") {
    UpdatesSheetView(
        state: .content,
        updates: [],
        history: [
            "Paris Coffee Spots",
            "Berlin Street Art",
            "London Pubs",
        ]
    )
}
