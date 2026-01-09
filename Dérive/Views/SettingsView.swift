//
//  SettingsView.swift
//  Dérive
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsService.shared

    var body: some View {
        Form {
            Section {
                Button {
                    settings.defaultMapApp = nil
                } label: {
                    HStack {
                        Image(systemName: settings.defaultMapApp == nil ? "circle.inset.filled" : "circle")
                            .foregroundStyle(settings.defaultMapApp == nil ? Color.accentColor : .secondary)
                        Text("Don't set default map app")
                    }
                }
                .foregroundStyle(.primary)

                ForEach(MapApp.allCases) { app in
                    Button {
                        settings.defaultMapApp = app
                    } label: {
                        HStack {
                            Image(systemName: settings.defaultMapApp == app ? "circle.inset.filled" : "circle")
                                .foregroundStyle(settings.defaultMapApp == app ? Color.accentColor : .secondary)
                            Text(app.displayName)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            } header: {
                Text("Choose default map app")
                    .foregroundStyle(.primary)
                    .textCase(nil)
            } footer: {
                Text("When set, tapping a notification will open your preferred map app directly instead of showing the map selection screen.")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
