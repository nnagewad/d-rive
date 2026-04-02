//
//  CityDetailView.swift
//  Purpose: Detail screen showing curated lists available for a specific city
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-16.
//

import SwiftUI

struct CityDetailView: View {
    let city: CityData

    var body: some View {
        Group {
            if city.lists.isEmpty {
                ContentUnavailableView {
                    Label("No Lists", systemImage: "list.bullet")
                } description: {
                    Text("No curated lists available for this city")
                }
            } else {
                List {
                    ForEach(city.lists) { list in
                        NavigationLink(value: list) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(list.name)
                                    if let curator = list.curator {
                                        Text(curator.name)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if list.notifyWhenNearby {
                                    Image(systemName: "bell.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("\(city.name), \(city.country)")
        .navigationBarTitleDisplayMode(.large)
    }
}
