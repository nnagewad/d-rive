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
    private let hasRequestedPermissionsKey = "hasRequestedNotificationPermissions"

    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()

    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined

    private var locationContinuation: CheckedContinuation<Bool, Never>?

    var hasRequestedPermissions: Bool {
        get { UserDefaults.standard.bool(forKey: hasRequestedPermissionsKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasRequestedPermissionsKey) }
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

    /// Request both notification and location permissions
    /// Returns true if both permissions are granted
    func requestPermissions() async -> Bool {
        hasRequestedPermissions = true

        // Request notifications first
        let notificationsGranted = await requestNotificationPermission()

        // Then request location
        let locationGranted = await requestLocationPermission()

        await refreshPermissionStatus()

        logger.info("Permissions requested - Notifications: \(notificationsGranted), Location: \(locationGranted)")

        return notificationsGranted && locationGranted
    }

    private func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            logger.info("Notification permission: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("Failed to request notification permission: \(error.localizedDescription)")
            return false
        }
    }

    private func requestLocationPermission() async -> Bool {
        let currentStatus = locationManager.authorizationStatus

        // Already authorized
        if currentStatus == .authorizedAlways || currentStatus == .authorizedWhenInUse {
            logger.info("Location already authorized: \(currentStatus.rawValue)")
            return true
        }

        // Request authorization and wait for delegate callback
        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestAlwaysAuthorization()
        }
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
