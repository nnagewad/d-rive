//
//  LocationListView.swift
//  Dérive
//

import SwiftUI
import os.log

struct LocationListView: View {
    @State private var geofences: [GeofenceConfiguration] = []
    @State private var errorMessage: String?

    private let logger = Logger(subsystem: "com.derive.app", category: "LocationListView")

    var body: some View {
        Group {
            if let error = errorMessage {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if geofences.isEmpty {
                ContentUnavailableView(
                    "No Locations",
                    systemImage: "mappin.slash",
                    description: Text("No geofences configured")
                )
            } else {
                List(geofences) { geofence in
                    NavigationLink {
                        MapSelectionView(
                            latitude: geofence.latitude,
                            longitude: geofence.longitude,
                            locationName: geofence.name,
                            group: geofence.group,
                            city: geofence.city,
                            country: geofence.country
                        )
                    } label: {
                        LocationRow(geofence: geofence)
                    }
                }
            }
        }
        .navigationTitle("Locations")
        .task {
            loadGeofences()
        }
    }

    private func loadGeofences() {
        do {
            geofences = try GeofenceLoaderService.shared.loadGeofences()
            logger.info("Loaded \(geofences.count) geofences")
        } catch {
            logger.error("Failed to load geofences: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Row View

struct LocationRow: View {
    let geofence: GeofenceConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(geofence.name)
                .font(.body)

            Text(geofence.group)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        LocationListView()
    }
}
