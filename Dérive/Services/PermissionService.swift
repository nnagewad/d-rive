//
//  PermissionService.swift
//  Dérive
//
//  Purpose: Handle notification and location permission requests
//

import Foundation
import Combine
import UserNotifications
import CoreLocation
import os.log

@MainActor
final class PermissionService: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = PermissionService()

    private let logger = Logger(subsystem: "com.derive.app", category: "PermissionService")
    private let hasRequestedNotificationPermissionsKey = "hasRequestedNotificationPermissions"
    private let hasRequestedLocationPermissionsKey = "hasRequestedLocationPermissions"

    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()

    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined

    private var locationContinuation: CheckedContinuation<Bool, Never>?

    var hasRequestedNotificationPermissions: Bool {
        get { UserDefaults.standard.bool(forKey: hasRequestedNotificationPermissionsKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasRequestedNotificationPermissionsKey) }
    }

    var hasRequestedLocationPermissions: Bool {
        get { UserDefaults.standard.bool(forKey: hasRequestedLocationPermissionsKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasRequestedLocationPermissionsKey) }
    }

    private override init() {
        super.init()
        Task {
            await refreshPermissionStatus()
        }
    }

    // MARK: - Permission Status

    func refreshPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
        locationStatus = locationManager.authorizationStatus
    }

    var hasRequiredPermissions: Bool {
        let hasNotifications = notificationStatus == .authorized || notificationStatus == .provisional
        let hasLocation = locationStatus == .authorizedAlways || locationStatus == .authorizedWhenInUse
        return hasNotifications && hasLocation
    }

    // MARK: - Request Permissions

    /// Request notification permission only
    /// Returns true if notification permission is granted
    func requestNotificationPermission() async -> Bool {
        hasRequestedNotificationPermissions = true
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshPermissionStatus()
            logger.info("Notification permission: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("Failed to request notification permission: \(error.localizedDescription)")
            return false
        }
    }

    /// Request location permission only
    /// Returns true if location permission is granted
    func requestLocationPermission() async -> Bool {
        hasRequestedLocationPermissions = true
        let currentStatus = locationManager.authorizationStatus

        // Already authorized
        if currentStatus == .authorizedAlways || currentStatus == .authorizedWhenInUse {
            logger.info("Location already authorized: \(currentStatus.rawValue)")
            return true
        }

        // Request authorization and wait for delegate callback
        let granted = await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestAlwaysAuthorization()
        }

        await refreshPermissionStatus()
        return granted
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            locationStatus = status

            if let continuation = locationContinuation {
                locationContinuation = nil
                let granted = status == .authorizedAlways || status == .authorizedWhenInUse
                logger.info("Location permission: \(granted ? "granted" : "denied")")
                continuation.resume(returning: granted)
            }
        }
    }
}
