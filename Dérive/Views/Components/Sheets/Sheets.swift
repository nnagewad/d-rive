//
//  Sheets.swift
//  Purpose: Reusable sheet components for modal presentations
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-30.
//

import SwiftUI
import UIKit

// MARK: - Map App Picker Sheet

/// Sheet for choosing default map app (shown on first Get Directions tap)
struct MapAppPickerSheet: View {
    var onSelect: (MapApp) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        onSelect(.appleMaps)
                    } label: {
                        HStack {
                            Spacer()
                            Text("Apple Maps")
                            Spacer()
                        }
                    }

                    Button {
                        onSelect(.googleMaps)
                    } label: {
                        HStack {
                            Spacer()
                            Text("Google Maps")
                            Spacer()
                        }
                    }
                } footer: {
                    Text("This will be your default map app for directions.")
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.top, 0)
            .navigationTitle("Select a Map App")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Spot Detail Sheet

/// Sheet showing details for a spot with Get Directions button
struct SpotDetailSheet: View {
    let spot: SpotData
    let onClose: () -> Void

    @ObservedObject private var settingsService = SettingsService.shared
    @State private var showMapAppPicker = false

    var body: some View {
        NavigationStack {
            List {
                // Info Section
                Section {
                    if !spot.category.isEmpty {
                        LabeledContent("Category", value: spot.category)
                    }

                    if let city = spot.list?.city {
                        LabeledContent("Location", value: "\(city.name), \(city.country)")
                    }

                    if let instagram = spot.instagramHandle {
                        Button {
                            openInstagram(instagram)
                        } label: {
                            HStack {
                                Spacer()
                                Text("Instagram")
                                Spacer()
                            }
                        }
                    }

                    if let website = spot.websiteURL {
                        Button {
                            openWebsite(website)
                        } label: {
                            HStack {
                                Spacer()
                                Text("Website")
                                Spacer()
                            }
                        }
                    }
                }

                // Directions Section
                Section {
                    Button {
                        handleGetDirections()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Get Directions")
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(spot.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.labelSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showMapAppPicker) {
            MapAppPickerSheet(
                onSelect: { mapApp in
                    settingsService.defaultMapApp = mapApp
                    showMapAppPicker = false
                    openDirections(with: mapApp)
                }
            )
            .presentationDetents([.height(220)])
        }
    }

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
            UIApplication.shared.open(url)
        }
    }

    private func openWebsite(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Previews

#Preview("Map App Picker Sheet") {
    struct PreviewWrapper: View {
        @State private var showSheet = true

        var body: some View {
            Button("Show Map App Picker") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                MapAppPickerSheet(
                    onSelect: { _ in showSheet = false }
                )
                .presentationDetents([.height(220)])
            }
        }
    }
    return PreviewWrapper()
}

#Preview("Spot Detail Sheet") {
    struct PreviewWrapper: View {
        @State private var showSheet = true

        var body: some View {
            Button("Show Spot Detail") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                SpotDetailSheet(
                    spot: SpotData(
                        name: "Café Lomi",
                        category: "Coffee",
                        latitude: 48.8566,
                        longitude: 2.3522,
                        radius: 100,
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
