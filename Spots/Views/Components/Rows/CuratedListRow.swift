//
//  CuratedListRow.swift
//  Purpose: Reusable row for displaying a curated list with follow/stop swipe actions
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2026-04-03.
//

import SwiftUI
import SwiftData

struct CuratedListRow: View {
    let list: CuratedListData
    let onFollow: () -> Void
    let onStop: () -> Void
    var navigable: Bool = true
    var subtitle: String? = nil

    var body: some View {
        Group {
            if navigable {
                NavigationLink(value: list) { rowContent }
            } else {
                rowContent
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if list.isDownloaded && list.notifyWhenNearby {
                Button(action: onStop) {
                    Label("Stop", systemImage: "bell.slash.fill")
                }
                .tint(.red)
            } else {
                Button(action: onFollow) {
                    Label("Follow", systemImage: "bell.fill")
                }
                .tint(.accentColor)
            }
        }
    }

    private var rowContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(list.name)
                let resolvedSubtitle = subtitle ?? list.curator?.name
                if let resolvedSubtitle {
                    Text(resolvedSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if list.isDownloaded && list.notifyWhenNearby {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.accent)
            }
        }
    }
}

// MARK: - Preview

@MainActor
private func makeCuratedListRowPreview() -> some View {
    let schema = Schema([CountryData.self, CityData.self, SpotCategoryData.self, CuratorData.self, CuratedListData.self, SpotData.self])
    let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let ctx = container.mainContext

    let curator = CuratorData(name: "Marie Dupont", bio: "Parisian food lover")
    let city = CityData(name: "Paris", countryData: CountryData(name: "France"))

    let following = CuratedListData(name: "After Work Spots", isDownloaded: true, notifyWhenNearby: true)
    following.curator = curator
    following.city = city

    let notFollowing = CuratedListData(name: "Weekend Brunch", isDownloaded: false, notifyWhenNearby: false)
    notFollowing.curator = curator
    notFollowing.city = city

    ctx.insert(curator)
    ctx.insert(city)
    ctx.insert(following)
    ctx.insert(notFollowing)

    return List {
        CuratedListRow(list: following, onFollow: {}, onStop: {})
        CuratedListRow(list: notFollowing, onFollow: {}, onStop: {})
    }
    .listStyle(.insetGrouped)
    .modelContainer(container)
}

#Preview("Curated List Row") { makeCuratedListRowPreview() }
