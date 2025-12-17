//
//  LocationManager.swift
//  Purpose: Live location (no geofencing)
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-16.
//

import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    @Published var latitude: Double?
    @Published var longitude: Double?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 5
    }

    func start() {
        manager.requestWhenInUseAuthorization()
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              location.horizontalAccuracy > 0,
              location.horizontalAccuracy <= 50 else { return }

        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
    }
}
