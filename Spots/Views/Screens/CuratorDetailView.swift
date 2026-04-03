//
//  CuratorDetailView.swift
//  Purpose: Profile screen for a curator — hero image, bio, and social links
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-16.
//

import SwiftUI
import SwiftData

struct CuratorDetailView: View {
    let curator: CuratorData
    @Environment(\.openURL) private var openURL

    private var hasImage: Bool { curator.imageUrl != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroView

                VStack(alignment: .leading, spacing: 0) {
                    // About
                    if !curator.bio.isEmpty || curator.instagramHandle != nil || curator.websiteURL != nil {
                        sectionHeader("About")
                        card {
                            if !curator.bio.isEmpty {
                                Text(curator.bio)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                            }
                            if let instagram = curator.instagramHandle {
                                Divider().padding(.leading)
                                cardButton("Instagram") { openInstagram(instagram) }
                            }
                            if let website = curator.websiteURL {
                                Divider().padding(.leading)
                                cardButton("Website") { openWebsite(website) }
                            }
                        }
                    }

                    // Lists
                    if !curator.lists.isEmpty {
                        sectionHeader(curator.lists.count == 1 ? "Curator's list" : "Curator's lists")
                        card {
                            NavigationLink {
                                CuratorListsView(curator: curator)
                            } label: {
                                HStack {
                                    Text("View all")
                                    Spacer()
                                    Text("\(curator.lists.count)")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: hasImage ? .top : [])
        .navigationTitle(hasImage ? "" : curator.name)
        .navigationBarTitleDisplayMode(hasImage ? .inline : .large)
        .toolbarBackground(hasImage ? .hidden : .automatic, for: .navigationBar)
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroView: some View {
        if let imageUrl = curator.imageUrl, let url = URL(string: imageUrl) {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.secondary.opacity(0.3)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 420)
                .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 420)

                Text(curator.name)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
            .frame(height: 420)
        }
    }

    // MARK: - Card Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 6)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    private func cardButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }

    // MARK: - URL Helpers

    private func openInstagram(_ value: String) {
        let urlString = value.hasPrefix("http") ? value : "https://instagram.com/\(value.trimmingCharacters(in: .init(charactersIn: "@")))"
        if let url = URL(string: urlString) { openURL(url) }
    }

    private func openWebsite(_ urlString: String) {
        let prefixed = urlString.hasPrefix("http") ? urlString : "https://\(urlString)"
        if let url = URL(string: prefixed) { openURL(url) }
    }
}

// MARK: - Preview

@MainActor
private func makeCuratorDetailPreview() -> some View {
    let schema = Schema([CountryData.self, CityData.self, SpotCategoryData.self, CuratorData.self, CuratedListData.self, SpotData.self])
    let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
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
    let schema = Schema([CountryData.self, CityData.self, SpotCategoryData.self, CuratorData.self, CuratedListData.self, SpotData.self])
    let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
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
