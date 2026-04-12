//
//  SpotDetailSheet.swift
//  Purpose: Modal sheet presenting spot details, directions, and links
//  Cool Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-30.
//

import SwiftUI
import os.log

// MARK: - Spot Detail Sheet

/// Half-sheet showing spot name, category, and action buttons
struct SpotDetailSheet: View {
    let spot: SpotData

    @Environment(\.openURL) private var openURL
    @ObservedObject private var settingsService = SettingsService.shared
    @State private var showMapAppPicker = false

    private let logger = Logger(subsystem: "com.nikin.spots", category: "SpotDetailSheet")

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Category subtitle
                if !spot.category.isEmpty {
                    Text(spot.category)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                }

                // Short description
                if let note = spot.shortNote, !note.isEmpty {
                    Text(note)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }

                Spacer()

                // Action buttons pinned to bottom
                VStack(spacing: 10) {
                    Button(action: handleGetDirections) {
                        Text("Get directions")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)

                    if let instagram = spot.instagramHandle {
                        Button { openURL.openInstagram(instagram) } label: {
                            Text("Instagram").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                    }

                    if let website = spot.websiteURL {
                        Button { openURL.openWebsite(website) } label: {
                            Text("Website").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle(spot.name)
            .navigationBarTitleDisplayMode(.large)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            logger.info("📋 Sheet opened: \(spot.name)")
        }
        .alert("Select a Map App", isPresented: $showMapAppPicker) {
            Button("Apple Maps") {
                settingsService.defaultMapApp = .appleMaps
                openDirections(with: .appleMaps)
            }
            Button("Google Maps") {
                settingsService.defaultMapApp = .googleMaps
                openDirections(with: .googleMaps)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will be your default map app for directions.")
        }
    }

    // MARK: - Actions

    private func handleGetDirections() {
        if let mapApp = settingsService.defaultMapApp {
            openDirections(with: mapApp)
        } else {
            showMapAppPicker = true
        }
    }

    private func openDirections(with mapApp: MapApp) {
        MapNavigationService.shared.openMapApp(
            mapApp,
            latitude: spot.latitude,
            longitude: spot.longitude
        )
    }

}

// MARK: - Previews

#Preview("All links + description") {
    struct PreviewWrapper: View {
        @State private var showSheet = true
        var body: some View {
            Button("Show Sheet") { showSheet = true }
                .sheet(isPresented: $showSheet) {
                    SpotDetailSheet(
                        spot: SpotData(
                            name: "Café Lomi",
                            latitude: 48.8566,
                            longitude: 2.3522,
                            categoryData: SpotCategoryData(name: "Coffee"),
                            instagramHandle: "@cafelomi",
                            websiteURL: "https://cafelomi.com",
                            shortNote: "A Parisian specialty coffee institution known for their light roasts and bright, clean brews."
                        )
                    )
                }
        }
    }
    return PreviewWrapper()
}

#Preview("No links, no description") {
    struct PreviewWrapper: View {
        @State private var showSheet = true
        var body: some View {
            Button("Show Sheet") { showSheet = true }
                .sheet(isPresented: $showSheet) {
                    SpotDetailSheet(
                        spot: SpotData(
                            name: "Boxcar Social",
                            latitude: 43.6677,
                            longitude: -79.3901
                        )
                    )
                }
        }
    }
    return PreviewWrapper()
}
