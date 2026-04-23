//
//  CuratorDetailView.swift
//  Purpose: Profile screen for a curator — hero image, bio, and social links
//  Cool Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-16.
//

import SwiftUI
import SwiftData

struct CuratorDetailView: View {
    let curator: CuratorData
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroView

                VStack(alignment: .leading, spacing: 24) {
                    if !curator.bio.isEmpty {
                        Text(curator.bio)
                    }

                    if curator.instagramHandle != nil || curator.websiteURL != nil {
                        HStack(spacing: 16) {
                            if let instagram = curator.instagramHandle {
                                Button("Instagram") { openURL.openInstagram(instagram) }
                                    .accessibilityHint("Opens Instagram")
                            }
                            if let website = curator.websiteURL {
                                Button("Website") { openURL.openWebsite(website) }
                                    .accessibilityHint("Opens website in browser")
                            }
                        }
                        .glassButtonStyle()
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                if curator.lists.count > 1 {
                    NavigationLink {
                        CuratorListsView(curator: curator)
                    } label: {
                        Text("View their lists")
                            .frame(maxWidth: .infinity)
                    }
                    .glassProminentButtonStyle()
                    .controlSize(.large)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                avatarCircle
                Spacer()
            }
            .padding(.top, 0)

            Text(curator.name)
                .font(.largeTitle.bold())
                .padding(.horizontal, 24)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var avatarCircle: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 300, height: 300)

            if let url = curator.imageUrl.flatMap(URL.init) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                    }
                }
                .frame(width: 300, height: 300)
                .clipShape(Circle())
                .accessibilityHidden(true)
            }
        }
    }

}

// MARK: - Preview

@MainActor
private func makeCuratorDetailPreview() -> some View {
    let container = PreviewContainer.container
    let ctx = container.mainContext

    let country = CountryData(name: "France")
    let city = CityData(name: "Paris", countryData: country)
    let curator = CuratorData(
        name: "Marie Dupont",
        bio: "Parisian food lover and weekend wanderer.",
        imageUrl: "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800",
        instagramHandle: "@mariedupont",
        websiteURL: "https://mariedupont.com"
    )

    let list1 = CuratedListData(name: "After Work Spots", isDownloaded: true, notifyWhenNearby: true)
    list1.city = city; list1.curator = curator

    let list2 = CuratedListData(name: "Weekend Brunch", isDownloaded: false)
    list2.city = city; list2.curator = curator

    ctx.insert(country); ctx.insert(city); ctx.insert(curator)
    [list1, list2].forEach { ctx.insert($0) }

    return NavigationStack {
        CuratorDetailView(curator: curator)
    }
    .modelContainer(container)
}

@MainActor
private func makeCuratorDetailNoImagePreview() -> some View {
    let container = PreviewContainer.container
    let ctx = container.mainContext

    let country = CountryData(name: "France")
    let city = CityData(name: "Paris", countryData: country)
    let curator = CuratorData(
        name: "Marie Dupont",
        bio: "Parisian food lover and weekend wanderer.",
        instagramHandle: "@mariedupont"
    )

    let list = CuratedListData(name: "After Work Spots", isDownloaded: false)
    list.city = city; list.curator = curator

    ctx.insert(country); ctx.insert(city); ctx.insert(curator); ctx.insert(list)

    return NavigationStack {
        CuratorDetailView(curator: curator)
    }
    .modelContainer(container)
}

#Preview("Curator Detail — With Image") { makeCuratorDetailPreview() }
#Preview("Curator Detail — No Image") { makeCuratorDetailNoImagePreview() }
