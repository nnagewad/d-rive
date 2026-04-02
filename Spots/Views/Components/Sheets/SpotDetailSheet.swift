//
//  SpotDetailSheet.swift
//  Purpose: Modal sheet presenting spot details, directions, and links
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-30.
//

import SwiftUI

// MARK: - Close Button

/// Sheet close button
private struct CloseButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .fontWeight(.medium)
        }
        .buttonBorderShape(.circle)
        .tint(.secondary)
    }
}

// MARK: - Spot Detail Sheet

/// Half-sheet showing spot name, category, and action buttons
struct SpotDetailSheet: View {
    let spot: SpotData
    let onClose: () -> Void

    @Environment(\.openURL) private var openURL
    @ObservedObject private var settingsService = SettingsService.shared
    @State private var showMapAppPicker = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Category subtitle
                if !spot.category.isEmpty {
                    Text(spot.category)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Spacing.medium)
                }

                Spacer()

                // Action buttons pinned to bottom
                VStack(spacing: Spacing.small) {
                    Button(action: handleGetDirections) {
                        Text("Get directions")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)

                    Button {
                        if let instagram = spot.instagramHandle { openInstagram(instagram) }
                    } label: {
                        Text("Instagram").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .disabled(spot.instagramHandle == nil)

                    Button {
                        if let website = spot.websiteURL { openWebsite(website) }
                    } label: {
                        Text("Website").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .disabled(spot.websiteURL == nil)
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.bottom, Spacing.medium)
            }
            .navigationTitle(spot.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton(action: onClose)
                        .controlSize(.large)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
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

    private func openInstagram(_ handle: String) {
        let cleanHandle = handle.replacingOccurrences(of: "@", with: "")
        if let url = URL(string: "https://instagram.com/\(cleanHandle)") {
            openURL(url)
        }
    }

    private func openWebsite(_ urlString: String) {
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }
}

// MARK: - Previews

#Preview("All links") {
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
                            websiteURL: "https://cafelomi.com"
                        ),
                        onClose: { showSheet = false }
                    )
                }
        }
    }
    return PreviewWrapper()
}

#Preview("No links") {
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
                        ),
                        onClose: { showSheet = false }
                    )
                }
        }
    }
    return PreviewWrapper()
}
