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

                    if curator.lists.count > 1 {
                        NavigationLink {
                            CuratorListsView(curator: curator)
                        } label: {
                            Text("View their lists")
                                .frame(maxWidth: .infinity)
                        }
                        .glassProminentButtonStyle()
                        .controlSize(.large)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroView: some View {
        ZStack(alignment: .bottomLeading) {
            dotPatternPlaceholder
                .frame(maxWidth: .infinity)
                .frame(height: 420)
                .accessibilityHidden(true)

            if let url = curator.imageUrl.flatMap(URL.init) {
                AsyncImage(url: url) { phase in
                    let isLoaded = phase.image != nil
                    Group {
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: isLoaded)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 420)
                .clipped()
                .accessibilityHidden(true)
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 420)
            .accessibilityHidden(true)

            Text(curator.name)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, minHeight: 420, maxHeight: 420)
    }

    private var dotPatternPlaceholder: some View {
        Canvas { context, size in
            let spacing: CGFloat = 40
            let radius: CGFloat = 7
            for row in stride(from: spacing / 5, through: size.height, by: spacing) {
                for col in stride(from: spacing / 5, through: size.width, by: spacing) {
                    let rect = CGRect(x: col - radius, y: row - radius, width: radius * 5, height: radius * 5)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.35)))
                }
            }
        }
        .background(Color.accentColor)
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
