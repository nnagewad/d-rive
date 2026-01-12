//
//  SettingsView.swift
//  Dérive
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject private var settings = SettingsService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // In-app settings section
                VStack(alignment: .leading, spacing: 0) {

                    // Settings card
                    VStack(spacing: 0) {
                        // Default Map App row
                        NavigationLink {
                            DefaultMapAppView()
                        } label: {
                            SettingsNavigationRow(
                                title: "Default Map App",
                                detail: settings.defaultMapApp?.displayName ?? "Ask Next Time"
                            )
                        }

                        Divider()
                            .padding(.leading, 16)

                        // App Console row
                        NavigationLink {
                            AppConsoleView()
                        } label: {
                            SettingsNavigationRow(
                                title: "App Console",
                                detail: nil
                            )
                        }
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                }

                // iOS app settings section
                VStack(alignment: .leading, spacing: 0) {
                    // Settings card
                    VStack(spacing: 0) {
                        // Location Access Settings row
                        Button {
                            openIOSSettings()
                        } label: {
                            SettingsActionRow(title: "iOS App Settings")
                        }
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 50)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Settings")
    }

    private func openIOSSettings() {
        // Opens the app's settings page where location permissions and notifications can be adjusted
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Settings Navigation Row Component

private struct SettingsNavigationRow: View {
    let title: String
    let detail: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            if let detail = detail {
                Text(detail)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(UIColor.tertiaryLabel))
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

// MARK: - Settings Action Row Component

private struct SettingsActionRow: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            Text("Open")
                .font(.body)
                .foregroundColor(.blue)
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
