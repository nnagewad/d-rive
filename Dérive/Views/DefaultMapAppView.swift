//
//  DefaultMapAppView.swift
//  Dérive
//

import SwiftUI
import UIKit

struct DefaultMapAppView: View {
    @ObservedObject private var settings = SettingsService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Options card
                VStack(spacing: 0) {
                    // Ask Next Time option
                    Button {
                        settings.defaultMapApp = nil
                    } label: {
                        SettingsOptionRow(
                            title: "Ask Next Time",
                            isSelected: settings.defaultMapApp == nil
                        )
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.leading, 16)

                    // Map app options
                    ForEach(Array(MapApp.allCases.enumerated()), id: \.element.id) { index, app in
                        Button {
                            settings.defaultMapApp = app
                        } label: {
                            SettingsOptionRow(
                                title: app.displayName,
                                isSelected: settings.defaultMapApp == app
                            )
                        }
                        .buttonStyle(.plain)

                        if index < MapApp.allCases.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)

                // Footer text
                Text("When set, selecting the notification will open your preferred map app.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
            }
            .padding(.top, 16)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Default Map App")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Settings Option Row Component

private struct SettingsOptionRow: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.blue)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        DefaultMapAppView()
    }
}
