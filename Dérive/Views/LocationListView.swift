//
//  LocationListView.swift
//  Dérive
//

import SwiftUI
import CoreLocation
import UIKit
import os.log

// MARK: - Sort Mode

enum LocationSortMode: String, CaseIterable {
    case alphabetical = "Alphabetical"
    case distance = "Distance"
}

// MARK: - Location List View

struct LocationListView: View {
    @State private var geofences: [GeofenceConfiguration] = []
    @State private var errorMessage: String?
    @State private var sortMode: LocationSortMode = .alphabetical
    @StateObject private var locationManager = LocationManager()

    private let logger = Logger(subsystem: "com.derive.app", category: "LocationListView")

    /// City name from geofences
    private var cityName: String {
        geofences.first?.city ?? "Locations"
    }

    /// User's current location as CLLocation
    private var userLocation: CLLocation? {
        guard let lat = locationManager.latitude, let lon = locationManager.longitude else {
            return nil
        }
        return CLLocation(latitude: lat, longitude: lon)
    }

    /// Groups locations alphabetically by first letter
    private var alphabeticalGroups: [(String, [GeofenceConfiguration])] {
        let grouped = Dictionary(grouping: geofences) { geofence in
            String(geofence.name.prefix(1)).uppercased()
        }
        return grouped.sorted { $0.key < $1.key }
    }

    /// Locations sorted by distance from user
    private var distanceSortedLocations: [GeofenceConfiguration] {
        guard let userLoc = userLocation else {
            return geofences
        }
        return geofences.sorted { first, second in
            let firstLocation = CLLocation(latitude: first.latitude, longitude: first.longitude)
            let secondLocation = CLLocation(latitude: second.latitude, longitude: second.longitude)
            return userLoc.distance(from: firstLocation) < userLoc.distance(from: secondLocation)
        }
    }

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
                listContent
            }
        }
        .navigationTitle(cityName)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(cityName)
                        .font(.headline)
                    Text("\(geofences.count) spots")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort", selection: $sortMode) {
                        ForEach(LocationSortMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .foregroundStyle(Color(UIColor.darkGray))
                }
            }
        }
        .onChange(of: sortMode) { _, newMode in
            if newMode == .distance {
                locationManager.start()
            }
        }
        .task {
            loadGeofences()
        }
    }

    @ViewBuilder
    private var listContent: some View {
        List {
            switch sortMode {
            case .alphabetical:
                ForEach(alphabeticalGroups, id: \.0) { section in
                    Section {
                        ForEach(section.1) { geofence in
                            locationRow(for: geofence)
                        }
                    } header: {
                        Text(section.0)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                }

            case .distance:
                Section {
                    ForEach(distanceSortedLocations) { geofence in
                        locationRow(for: geofence)
                    }
                } header: {
                    Text("Closest first")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func locationRow(for geofence: GeofenceConfiguration) -> some View {
        ZStack(alignment: .leading) {
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
                EmptyView()
            }
            .opacity(0)

            LocationRow(geofence: geofence)
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

// MARK: - Location Row

struct LocationRow: View {
    let geofence: GeofenceConfiguration

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(geofence.name)
                    .font(.body)
                    .foregroundStyle(Color.primary)

                Text(geofence.group)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "info.circle")
                .font(.body)
                .foregroundStyle(.blue)
        }
        .frame(height: 52)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        LocationListView()
    }
}
