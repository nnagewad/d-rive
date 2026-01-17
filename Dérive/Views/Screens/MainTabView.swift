import SwiftUI

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
}

#Preview("Curated Lists Tab") {
    MainTabView(selectedTab: .curatedLists)
}

#Preview("Settings Tab") {
    MainTabView(selectedTab: .settings)
}
