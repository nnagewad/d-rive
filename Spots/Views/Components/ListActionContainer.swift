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

    @ViewBuilder let content: (
        _ follow: @escaping (CuratedListData) -> Void,
        _ stop: @escaping (CuratedListData) -> Void
    ) -> Content

    var body: some View {
        content(follow, stop)
            .notificationsPermissionAlert(isPresented: $showPermissionAlert)
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
