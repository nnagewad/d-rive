//
//  CuratorDetailView.swift
//  Purpose: Detail screen for a curator — bio, Instagram, and their curated lists
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-16.
//

import SwiftUI

struct CuratorDetailView: View {
    let curator: CuratorData
    @Environment(\.openURL) private var openURL

    private var listsGroupedByCity: [(city: CityData?, lists: [CuratedListData])] {
        let grouped = Dictionary(grouping: curator.lists, by: { $0.city?.id })
        return grouped.map { (city: $0.value.first?.city, lists: $0.value.sorted { $0.name < $1.name }) }
            .sorted { ($0.city?.name ?? "") < ($1.city?.name ?? "") }
    }

    var body: some View {
        List {
            if !curator.bio.isEmpty || curator.instagramHandle != nil {
                Section {
                    if !curator.bio.isEmpty {
                        Text(curator.bio)
                            .foregroundStyle(.secondary)
                    }

                    if let instagram = curator.instagramHandle {
                        Button {
                            openInstagram(instagram)
                        } label: {
                            Text("Instagram")
                                .frame(maxWidth: .infinity)
                        }
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    }
                }
            }

            if !curator.lists.isEmpty {
                ForEach(listsGroupedByCity, id: \.city?.id) { group in
                    Section(group.city != nil ? "\(group.city!.name), \(group.city!.country)" : "Lists") {
                        ForEach(group.lists) { list in
                            NavigationLink(value: list) {
                                HStack {
                                    Text(list.name)
                                    Spacer()
                                    if list.notifyWhenNearby {
                                        Image(systemName: "bell.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(curator.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private func openInstagram(_ handle: String) {
        let cleanHandle = handle.replacingOccurrences(of: "@", with: "")
        if let url = URL(string: "https://instagram.com/\(cleanHandle)") {
            openURL(url)
        }
    }
}
