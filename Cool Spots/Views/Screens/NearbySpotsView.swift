//
//  NearbySpotsView.swift
//  Purpose: Nearby spots list, sorted by distance. Rendered by HomeView when spots and location are available.
//  Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-16.
//

import SwiftUI

struct NearbySpotsView: View {
    let spots: [SpotData]
    var onSpotSelected: (SpotData) -> Void

    var body: some View {
        List {
            Section {
                ForEach(spots) { spot in
                    SpotRow(name: spot.name) {
                        onSpotSelected(spot)
                    }
                }
            } header: {
                Text("What's near me?")
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
        .standardListStyle()
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        NearbySpotsView(spots: [
            SpotData(name: "Sam James Coffee Bar", latitude: 43.6544, longitude: -79.4055),
            SpotData(name: "Pilot Coffee Roasters", latitude: 43.6465, longitude: -79.3963),
            SpotData(name: "Boxcar Social", latitude: 43.6677, longitude: -79.3901)
        ]) { _ in }
        .navigationTitle("Cool Spots")
        .navigationBarTitleDisplayMode(.large)
    }
}
