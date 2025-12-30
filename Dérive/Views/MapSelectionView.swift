//
//  MapSelectionView.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-30.
//

import SwiftUI
import MapKit
import os.log

struct MapSelectionView: View {
    let latitude: Double
    let longitude: Double
    let locationName: String
    let group: String
    let city: String
    let country: String

    @Environment(\.dismiss) private var dismiss
    private let logger = Logger(subsystem: "com.derive.app", category: "MapSelectionView")

    var body: some View {
        VStack(spacing: 24) {
            // Static Map
            Map(position: .constant(MapCameraPosition.region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            ))) {
                Marker(locationName, coordinate: CLLocationCoordinate2D(
                    latitude: latitude,
                    longitude: longitude
                ))
            }
            .frame(height: 300)
            .cornerRadius(12)
            .allowsHitTesting(false)
            .padding(.horizontal)

            // Location Info
            VStack(spacing: 12) {
                // Name
                Text(locationName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                // Group Tag
                if !group.isEmpty {
                    Text(group)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }

                VStack(spacing: 4) {
                    // City, Country
                    if !city.isEmpty || !country.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(city)\(!city.isEmpty && !country.isEmpty ? ", " : "")\(country)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Coordinates
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.4f", latitude)), \(String(format: "%.4f", longitude))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontDesign(.monospaced)
                    }
                }
            }
            .padding(.horizontal)

            // Navigation Buttons
            VStack(spacing: 12) {
                Button {
                    logger.info("🗺️ Opening Apple Maps for: \(locationName)")
                    MapNavigationService.shared.openAppleMaps(latitude: latitude, longitude: longitude)
                    dismiss()
                } label: {
                    Text("Open in Apple Maps")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    logger.info("🗺️ Opening Google Maps for: \(locationName)")
                    MapNavigationService.shared.openGoogleMaps(latitude: latitude, longitude: longitude)
                    dismiss()
                } label: {
                    Text("Open in Google Maps")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
        .navigationTitle("Navigate to \(locationName)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MapSelectionView(
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "San Francisco",
            group: "Landmarks",
            city: "San Francisco",
            country: "USA"
        )
    }
}
