//
//  PermissionService.swift
//  Cool Spots
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

    private let logger = Logger(subsystem: "com.nikin.spots", category: "PermissionService")
    private let hasRequestedNotificationPermissionsKey = "hasRequestedNotificationPermissions"
    private let hasRequestedLocationPermissionsKey = "hasRequestedLocationPermissions"

    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()

    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var locationStatus: CLAuthorizationStatus = CLLocationManager().authorizationStatus

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

    // MARK: - List Activation

    /// Requests permissions in the correct sequence for list activation:
    /// 1. Location "while using"  2. Notifications  3. Location "always" upgrade
    /// Returns true if notifications are authorised and the activation should proceed.
    func requestPermissionsForListActivation() async -> Bool {
        // Step 1: Location "while using"
        if !hasRequestedLocationPermissions {
            _ = await requestWhenInUseOnly()
        }

        // Step 2: Notifications
        let notificationsGranted: Bool
        if !hasRequestedNotificationPermissions {
            notificationsGranted = await requestNotificationPermission()
        } else {
            await refreshPermissionStatus()
            notificationsGranted = notificationStatus == .authorized || notificationStatus == .provisional
        }

        // Step 3: Always upgrade — fires after notifications, non-blocking
        fireAlwaysUpgrade()

        return notificationsGranted
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
    /// Returns true if any location permission is granted
    func requestLocationPermission() async -> Bool {
        hasRequestedLocationPermissions = true
        let currentStatus = locationManager.authorizationStatus

        if currentStatus == .authorizedAlways {
            logger.info("Location already authorized: always")
            return true
        }

        if currentStatus == .authorizedWhenInUse {
            // Already sufficient — fire the upgrade without blocking.
            // The delegate will update locationStatus if the user later grants always.
            locationManager.requestAlwaysAuthorization()
            await refreshPermissionStatus()
            return true
        }

        guard currentStatus == .notDetermined else {
            await refreshPermissionStatus()
            return false
        }

        // Step 1: Request when-in-use first (required by Apple before requesting always)
        let whenInUse = await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestWhenInUseAuthorization()
        }

        await refreshPermissionStatus()

        if whenInUse {
            // Fire the always upgrade without blocking — whenInUse is sufficient.
            // If the user declines the upgrade the status stays authorizedWhenInUse
            // and the delegate won't fire (no change), so we must not await here.
            locationManager.requestAlwaysAuthorization()
        }

        return whenInUse
    }

    // MARK: - Private Helpers

    /// Requests "when in use" only — does not fire the always upgrade.
    private func requestWhenInUseOnly() async -> Bool {
        hasRequestedLocationPermissions = true
        let currentStatus = locationManager.authorizationStatus

        if currentStatus == .authorizedAlways || currentStatus == .authorizedWhenInUse {
            return true
        }

        guard currentStatus == .notDetermined else {
            await refreshPermissionStatus()
            return false
        }

        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestWhenInUseAuthorization()
        }
    }

    /// Fires the "always" upgrade non-blocking. Safe when the user declines — no
    /// continuation means the missing delegate callback won't cause a hang.
    private func fireAlwaysUpgrade() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse else { return }
        locationManager.requestAlwaysAuthorization()
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
