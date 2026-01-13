//
//  CityListView.swift
//  Dérive
//
//  Purpose: Display available cities and handle download/selection
//

import SwiftUI
import UIKit
import os.log

struct CityListView: View {
    @StateObject private var cityService = CityService.shared
    @State private var errorMessage: String?
    @State private var showingError = false

    private let logger = Logger(subsystem: "com.derive.app", category: "CityListView")

    /// Groups cities alphabetically by their first letter
    private var groupedCities: [(String, [City])] {
        guard let manifest = cityService.manifest else { return [] }
        let grouped = Dictionary(grouping: manifest.cities) { city in
            String(city.name.prefix(1)).uppercased()
        }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        Group {
            if cityService.isLoadingManifest && cityService.manifest == nil {
                ProgressView("Loading cities...")
            } else if cityService.manifest != nil {
                List {
                    ForEach(groupedCities, id: \.0) { section in
                        Section {
                            ForEach(section.1) { city in
                                CityRow(
                                    city: city,
                                    isDownloaded: cityService.isCityDownloaded(city.id),
                                    isDownloading: cityService.downloadingCities.contains(city.id),
                                    needsUpdate: cityService.cityNeedsUpdate(city),
                                    onDownload: { downloadCity(city) }
                                )
                            }
                        } header: {
                            Text(section.0)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    ContentUnavailableView(
                        "Unable to Load Cities",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                    Button("Retry") {
                        Task { await loadManifest() }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                VStack(spacing: 16) {
                    ContentUnavailableView(
                        "No Cities Available",
                        systemImage: "map",
                        description: Text("Unable to fetch city list")
                    )
                    Button("Retry") {
                        Task { await loadManifest() }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("Cities")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(Color(UIColor.darkGray))
                }
            }
        }
        .task {
            await loadManifest()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func loadManifest() async {
        do {
            _ = try await cityService.fetchManifest()
            errorMessage = nil
        } catch {
            logger.error("Failed to fetch manifest: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    private func downloadCity(_ city: City) {
        Task {
            do {
                try await cityService.downloadCity(city)
                logger.info("Downloaded city: \(city.name)")
            } catch {
                logger.error("Failed to download city: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - City Row

struct CityRow: View {
    let city: City
    let isDownloaded: Bool
    let isDownloading: Bool
    let needsUpdate: Bool
    let onDownload: () -> Void

    var body: some View {
        Group {
            if isDownloaded && !needsUpdate {
                // Downloaded and up to date - navigate to locations
                NavigationLink(destination: LocationListView()) {
                    rowContent
                }
            } else {
                // Not downloaded or needs update - download action
                Button(action: onDownload) {
                    rowContent
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 44)
    }

    private var rowContent: some View {
        HStack {
            Text(city.name)
                .font(.body)
                .foregroundStyle(Color.primary)

            Spacer()

            if isDownloading {
                ProgressView()
                    .controlSize(.small)
            } else if !isDownloaded {
                // Download icon (plus circle)
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundStyle(.blue)
            } else if needsUpdate {
                // Update available icon
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            // NavigationLink provides its own chevron for downloaded cities
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        CityListView()
    }
}
