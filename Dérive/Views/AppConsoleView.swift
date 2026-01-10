//
//  AppConsoleView.swift
//  Dérive
//
//  Created by Nikin Nagewadia on 2025-12-16.
//

import SwiftUI
import UserNotifications
import CoreLocation
import os.log

struct AppConsoleView: View {

    @StateObject private var locationManager = LocationManager()
    @ObservedObject private var geofenceManager = GeofenceManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator

    @State private var notificationAuthStatus: String = "Unknown"
    @State private var alertSetting: String = "Unknown"
    @State private var soundSetting: String = "Unknown"

    private let logger = Logger(subsystem: "com.derive.app", category: "AppConsoleView")

    // MARK: - Computed Properties

    private var locationAuthorizationStatus: String {
        switch locationManager.authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Authorized (Always)"
        case .authorizedWhenInUse: return "Authorized (When In Use)"
        @unknown default: return "Unknown"
        }
    }

    private var locationAuthColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return .green
        case .denied: return .red
        case .restricted: return .orange
        default: return .gray
        }
    }

    private var scenePhaseName: String {
        switch scenePhase {
        case .active: return "Active"
        case .inactive: return "Inactive"
        case .background: return "Background"
        @unknown default: return "Unknown"
        }
    }

    private var locationModeName: String {
        scenePhase == .active ? "Foreground (High Accuracy)" : "Background (Reduced)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("App Console")
                    .font(.title)
                    .fontWeight(.bold)

                Divider()

                // Current Location
                GroupBox(label: Text("Current Location").font(.headline)) {
                    VStack(spacing: 8) {
                        if let lat = locationManager.latitude,
                           let lon = locationManager.longitude {
                            Text(String(format: "Lat: %.5f", lat))
                                .font(.system(.body, design: .monospaced))
                            Text(String(format: "Lon: %.5f", lon))
                                .font(.system(.body, design: .monospaced))
                        } else {
                            Text("Waiting for location…")
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                Divider()

                // Location Authorization
                GroupBox(label: Text("Location Authorization").font(.headline)) {
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(locationAuthColor)
                            Text(locationAuthorizationStatus)
                                .font(.caption)
                                .foregroundColor(locationAuthColor)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                // Geofence Status
                GroupBox(label: Text("Geofence Status").font(.headline)) {
                    VStack(spacing: 8) {
                        Text(
                            geofenceManager.isInsideGeofence
                            ? "🟢 Inside geofence"
                            : "🔴 Outside geofence"
                        )
                        .font(.subheadline)
                        .fontWeight(.medium)

                        Text("Distance: \(geofenceManager.currentDistance)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                Divider()

                // Active Geofences List
                GroupBox(label: Text("Active Geofences (\(geofenceManager.geofenceInfoList.count))").font(.headline)) {
                    if geofenceManager.geofenceInfoList.isEmpty {
                        Text("No geofences loaded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(geofenceManager.geofenceInfoList) { geofence in
                                    HStack {
                                        Text(geofence.name)
                                            .font(.caption)
                                        Spacer()
                                        Text("\(geofence.distance)m")
                                            .font(.caption)
                                            .fontDesign(.monospaced)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 150)
                    }
                }

                Divider()

                // Notification Settings
                GroupBox(label: Text("Notification Settings").font(.headline)) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Authorization:")
                                .font(.caption)
                            Text(notificationAuthStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        HStack {
                            Text("Alerts:")
                                .font(.caption)
                            Text(alertSetting)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        HStack {
                            Text("Sounds:")
                                .font(.caption)
                            Text(soundSetting)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                // App State
                GroupBox(label: Text("App State").font(.headline)) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Scene Phase:")
                                .font(.caption)
                            Text(scenePhaseName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        HStack {
                            Text("Location Mode:")
                                .font(.caption)
                            Text(locationModeName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                // Debug Logs
                GroupBox(label: Text("Debug Logs").font(.headline)) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(geofenceManager.debugLogs, id: \.self) { log in
                                Text(log)
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(maxHeight: 250)
                    .padding(8)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()

            // Store notification settings for display
            switch settings.authorizationStatus {
            case .authorized: notificationAuthStatus = "Authorized"
            case .denied: notificationAuthStatus = "Denied"
            case .notDetermined: notificationAuthStatus = "Not Determined"
            case .provisional: notificationAuthStatus = "Provisional"
            case .ephemeral: notificationAuthStatus = "Ephemeral"
            @unknown default: notificationAuthStatus = "Unknown"
            }

            switch settings.alertSetting {
            case .enabled: alertSetting = "Enabled"
            case .disabled: alertSetting = "Disabled"
            case .notSupported: alertSetting = "Not Supported"
            @unknown default: alertSetting = "Unknown"
            }

            switch settings.soundSetting {
            case .enabled: soundSetting = "Enabled"
            case .disabled: soundSetting = "Disabled"
            case .notSupported: soundSetting = "Not Supported"
            @unknown default: soundSetting = "Unknown"
            }

            // Start location updates for display in console
            locationManager.start()
        }
        .onDisappear {
            locationManager.stop()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                locationManager.setForegroundMode(true)
            case .inactive, .background:
                locationManager.setForegroundMode(false)
            @unknown default:
                break
            }
        }
    }
}


#Preview {
    AppConsoleView()
        .environmentObject(NavigationCoordinator.shared)
}
