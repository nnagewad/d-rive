//
//  SettingsView.swift
//  Dérive
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section {
                NavigationLink("Default Map App") {
                    DefaultMapAppView()
                }
                NavigationLink("App Console") {
                    AppConsoleView()
                }
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
