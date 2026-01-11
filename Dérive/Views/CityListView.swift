//
//  CityListView.swift
//  Dérive
//
//  Purpose: Display available cities and handle download/selection
//

import SwiftUI
import os.log

struct CityListView: View {
    @StateObject private var cityService = CityService.shared
    @State private var errorMessage: String?
    @State private var showingError = false

    @Binding var hasSelectedCity: Bool

    private let logger = Logger(subsystem: "com.derive.app", category: "CityListView")

    var body: some View {
        Group {
            if cityService.isLoadingManifest && cityService.manifest == nil {
                ProgressView("Loading cities...")
            } else if let manifest = cityService.manifest {
                List(manifest.cities) { city in
                    CityRow(
                        city: city,
                        isDownloaded: cityService.isCityDownloaded(city.id),
                        isDownloading: cityService.downloadingCities.contains(city.id),
                        isSelected: cityService.selectedCityId == city.id,
                        needsUpdate: cityService.cityNeedsUpdate(city),
                        onDownload: { downloadAndSelectCity(city) },
                        onSelect: { selectCity(city) }
                    )
                }
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
        .navigationTitle("Select City")
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

    private func downloadAndSelectCity(_ city: City) {
        Task {
            do {
                try await cityService.downloadCity(city)
                try cityService.selectCity(city.id)
                hasSelectedCity = true
                logger.info("Downloaded and selected city: \(city.name)")
            } catch {
                logger.error("Failed to download city: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }

    private func selectCity(_ city: City) {
        do {
            try cityService.selectCity(city.id)
            hasSelectedCity = true
            logger.info("Selected city: \(city.name)")
        } catch {
            logger.error("Failed to select city: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - City Row

struct CityRow: View {
    let city: City
    let isDownloaded: Bool
    let isDownloading: Bool
    let isSelected: Bool
    let needsUpdate: Bool
    let onDownload: () -> Void
    let onSelect: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(city.name)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }

                Text("\(city.country) • \(city.geofenceCount) locations")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isDownloading {
                ProgressView()
                    .controlSize(.small)
            } else if !isDownloaded {
                Button(action: onDownload) {
                    Label("Download", systemImage: "arrow.down.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else if needsUpdate {
                Button(action: onDownload) {
                    Label("Update", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else if !isSelected {
                Button("Select", action: onSelect)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        CityListView(hasSelectedCity: .constant(false))
    }
}
