//
//  HomeView.swift
//  Purpose: Root app view with spots list and navigation to curated lists and settings
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2026-04-01.
//

import SwiftUI
import SwiftData

private enum HomeDestination: Hashable {
    case curatedLists
    case settings
}

struct HomeView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @State private var spotForSheet: SpotData?

    var body: some View {
        NavigationStack {
            NearbySpotsView()
                .navigationTitle("Spots")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        NavigationLink(value: HomeDestination.curatedLists) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.circle)

                        NavigationLink(value: HomeDestination.settings) {
                            Image(systemName: "gearshape.fill")
                        }
                        .labelStyle(.iconOnly)
                        .tint(.primary)
                    }
                }
                .navigationDestination(for: HomeDestination.self) { destination in
                    switch destination {
                    case .curatedLists: CuratedListsView()
                    case .settings: SettingsView()
                    }
                }
        }
        .sheet(item: $spotForSheet) { spot in
            SpotDetailSheet(spot: spot) {
                navigationCoordinator.dismissSpotDetail()
                spotForSheet = nil
            }
        }
        .onAppear {
            if let spotId = navigationCoordinator.selectedSpotId, spotForSheet == nil {
                spotForSheet = DataService.shared.getSpot(byId: spotId)
            }
        }
        .onChange(of: navigationCoordinator.selectedSpotId) { _, newValue in
            if let spotId = newValue {
                spotForSheet = DataService.shared.getSpot(byId: spotId)
            } else {
                spotForSheet = nil
            }
        }
    }
}

// MARK: - Previews

#Preview("Light") {
    HomeView()
        .environmentObject(NavigationCoordinator.shared)
        .modelContainer(PreviewContainer.containerWithData)
}

#Preview("Dark") {
    HomeView()
        .environmentObject(NavigationCoordinator.shared)
        .modelContainer(PreviewContainer.containerWithData)
        .preferredColorScheme(.dark)
}
