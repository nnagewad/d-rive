import SwiftUI
import SwiftData

// MARK: - Main Tab View

/// Main app container with custom tab bar navigation
struct MainTabView: View {
    @State private var selectedTab: TabItem

    init(selectedTab: TabItem = .nearbySpots) {
        _selectedTab = State(initialValue: selectedTab)
    }

    var body: some View {
        TabBarContainer(selectedTab: $selectedTab) {
            ZStack {
                switch selectedTab {
                case .nearbySpots:
                    NearbySpotsView()
                case .curatedLists:
                    CuratedListsView()
                case .settings:
                    NewSettingsView()
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Main Tab View") {
    MainTabView()
        .modelContainer(PreviewContainer.containerWithData)
}

#Preview("Curated Lists Tab") {
    MainTabView(selectedTab: .curatedLists)
        .modelContainer(PreviewContainer.containerWithData)
}

#Preview("Settings Tab") {
    MainTabView(selectedTab: .settings)
        .modelContainer(PreviewContainer.containerWithData)
}
