//
//  NotificationsPermissionAlertModifier.swift
//  Purpose: View modifier for the notifications permission alert
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2026-04-03.
//

import SwiftUI

private struct NotificationsPermissionAlert: ViewModifier {
    @Binding var isPresented: Bool
    @Environment(\.openURL) private var openURL

    func body(content: Content) -> some View {
        content.alert("Notifications Required", isPresented: $isPresented) {
            Button("Open Settings") { openURL(.appSettings) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable notifications in Settings to receive nearby spot alerts.")
        }
    }
}

extension View {
    func notificationsPermissionAlert(isPresented: Binding<Bool>) -> some View {
        modifier(NotificationsPermissionAlert(isPresented: isPresented))
    }
}
