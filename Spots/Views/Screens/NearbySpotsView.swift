//
//  NearbySpotsView.swift
//  Purpose: Nearby spots list, sorted by distance. Rendered by HomeView when spots and location are available.
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-16.
//

import SwiftUI

struct NearbySpotsView: View {
    let spots: [SpotData]
    @State private var selectedSpot: SpotData?

    var body: some View {
        List {
            Section {
                ForEach(spots) { spot in
                    SpotRow(name: spot.name) {
                        selectedSpot = spot
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("What's near me?")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("The closest spot appears at the top of the list.")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .textCase(nil)
                .padding(.bottom, 4)
            }
        }
        .standardListStyle()
        .spotDetailSheet(item: $selectedSpot) { selectedSpot = nil }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        NearbySpotsView(spots: [
            SpotData(name: "Sam James Coffee Bar", latitude: 43.6544, longitude: -79.4055),
            SpotData(name: "Pilot Coffee Roasters", latitude: 43.6465, longitude: -79.3963),
            SpotData(name: "Boxcar Social", latitude: 43.6677, longitude: -79.3901)
        ])
        .navigationTitle("Spots")
        .navigationBarTitleDisplayMode(.large)
    }
}
