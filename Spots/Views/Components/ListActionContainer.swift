//
//  ListActionContainer.swift
//  Purpose: Wrapper that provides follow/stop list actions and the permission alert to any view
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2026-04-03.
//

import SwiftUI

struct ListActionContainer<Content: View>: View {
    @State private var showPermissionAlert = false
    @Environment(\.openURL) private var openURL

    @ViewBuilder let content: (
        _ follow: @escaping (CuratedListData) -> Void,
        _ stop: @escaping (CuratedListData) -> Void
    ) -> Content

    var body: some View {
        content(follow, stop)
            .alert("Notifications Required", isPresented: $showPermissionAlert) {
                Button("Open Settings") { openURL(URL(string: "app-settings:")!) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enable notifications in Settings to receive alerts when you're near any spots on this list.")
            }
    }

    private func follow(_ list: CuratedListData) {
        Task {
            if !(await ListActionService.shared.follow(list)) {
                showPermissionAlert = true
            }
        }
    }

    private func stop(_ list: CuratedListData) {
        ListActionService.shared.stop(list)
    }
}
