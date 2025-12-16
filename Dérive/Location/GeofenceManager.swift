//
//  GeofenceManager.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-16.
//

import CoreLocation
import Combine

final class GeofenceManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isInsideGeofence = false
    private let manager = CLLocationManager()
    private var isMonitoring = false

    override init() {
        super.init()
        manager.delegate = self
        manager.requestAlwaysAuthorization()
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        let center = CLLocationCoordinate2D(
            latitude: 51.61814,
            longitude: -0.18463
        )

        let region = CLCircularRegion(
            center: center,
            radius: 100,
            identifier: "TestGeofence"
        )

        region.notifyOnEntry = true
        region.notifyOnExit = true

        manager.startMonitoring(for: region)
        print("Started monitoring geofence")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            print("Geofence authorized: Always")
        case .authorizedWhenInUse:
            print("Geofence only When In Use (Always not granted yet)")
        default:
            print("Geofence not authorized")
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region:", region.identifier)
        DispatchQueue.main.async {
            self.isInsideGeofence = true
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region:", region.identifier)
        DispatchQueue.main.async {
            self.isInsideGeofence = false
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         monitoringDidFailFor region: CLRegion?,
                         withError error: Error) {
        print("Geofence error:", error)
    }
}
