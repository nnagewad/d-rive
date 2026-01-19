//
//  MainTabView.swift
//  Purpose: Main app container with tab navigation
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-30.
//

import SwiftUI
import SwiftData

// MARK: - Main Tab View

/// Main app container using native iOS TabView
/// iOS 26: Automatically gets liquid glass tab bar styling and dark mode support
struct MainTabView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var selectedTab: TabItem
    @State private var spotForSheet: SpotData?

    init(selectedTab: TabItem = .nearbySpots) {
        _selectedTab = State(initialValue: selectedTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NearbySpotsView()
                .tabItem {
                    Label(TabItem.nearbySpots.title, systemImage: TabItem.nearbySpots.icon)
                }
                .tag(TabItem.nearbySpots)

            CuratedListsView()
                .tabItem {
                    Label(TabItem.curatedLists.title, systemImage: TabItem.curatedLists.icon)
                }
                .tag(TabItem.curatedLists)

            NewSettingsView()
                .tabItem {
                    Label(TabItem.settings.title, systemImage: TabItem.settings.icon)
                }
                .tag(TabItem.settings)
        }
        .onChange(of: navigationCoordinator.selectedSpotId) { _, newValue in
            if let spotId = newValue {
                spotForSheet = DataService.shared.getSpot(byId: spotId)
            } else {
                spotForSheet = nil
            }
        }
        .sheet(item: $spotForSheet) { spot in
            SpotDetailSheet(spot: spot) {
                navigationCoordinator.dismissSpotDetail()
                spotForSheet = nil
            }
        }
    }
}

// MARK: - Previews

#Preview("Main Tab View") {
    MainTabView()
        .environmentObject(NavigationCoordinator.shared)
        .modelContainer(PreviewContainer.containerWithData)
}

#Preview("Curated Lists Tab") {
    MainTabView(selectedTab: .curatedLists)
        .environmentObject(NavigationCoordinator.shared)
        .modelContainer(PreviewContainer.containerWithData)
}

#Preview("Settings Tab") {
    MainTabView(selectedTab: .settings)
        .environmentObject(NavigationCoordinator.shared)
        .modelContainer(PreviewContainer.containerWithData)
}
