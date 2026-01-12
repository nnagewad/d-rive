//
//  AppConsoleView.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-16.
//

import SwiftUI
import UIKit
import CoreLocation
import MapKit

struct AppConsoleView: View {

    @StateObject private var locationManager = LocationManager()
    @ObservedObject private var geofenceManager = GeofenceManager.shared
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator

    @State private var locationDescription: String = "an unknown location"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Your coordinates section
                VStack(alignment: .leading, spacing: 0) {
                    // Section header
                    Text("Your coordinates")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                    // Coordinates card
                    VStack(spacing: 0) {
                        // Latitude row
                        SettingsRow(
                            title: "Latitude",
                            value: locationManager.latitude.map { String(format: "%.5f", $0) } ?? "—"
                        )

                        Divider()
                            .padding(.leading, 16)

                        // Longitude row
                        SettingsRow(
                            title: "Longitude",
                            value: locationManager.longitude.map { String(format: "%.5f", $0) } ?? "—"
                        )
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)

                    // Footer text
                    Text("Based on your coordinates you are presently located in \(locationDescription).")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                }

                // Active geofences section
                VStack(alignment: .leading, spacing: 0) {
                    // Geofences card
                    VStack(spacing: 0) {
                        SettingsRow(
                            title: "Active geofences",
                            value: "\(geofenceManager.geofenceInfoList.count)"
                        )
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)

                    // Footer text
                    Text("Dérive can monitor up to 20 nearest geofences based on your location.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 50)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("App Console")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            locationManager.start()
        }
        .onDisappear {
            locationManager.stop()
        }
        .onChange(of: locationManager.latitude) { _, _ in
            reverseGeocode()
        }
        .onChange(of: locationManager.longitude) { _, _ in
            reverseGeocode()
        }
    }

    private func reverseGeocode() {
        guard let lat = locationManager.latitude,
              let lon = locationManager.longitude else {
            locationDescription = "an unknown location"
            return
        }

        let location = CLLocation(latitude: lat, longitude: lon)
        guard let request = MKReverseGeocodingRequest(location: location) else {
            locationDescription = "your current area"
            return
        }

        Task {
            do {
                let mapItems = try await request.mapItems
                if let mapItem = mapItems.first {
                    if let shortAddress = mapItem.address?.shortAddress, !shortAddress.isEmpty {
                        locationDescription = shortAddress
                    } else if let fullAddress = mapItem.address?.fullAddress, !fullAddress.isEmpty {
                        locationDescription = fullAddress
                    } else {
                        locationDescription = "your current area"
                    }
                }
            } catch {
                locationDescription = "your current area"
            }
        }
    }
}

// MARK: - Settings Row Component

private struct SettingsRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        AppConsoleView()
            .environmentObject(NavigationCoordinator.shared)
    }
}
