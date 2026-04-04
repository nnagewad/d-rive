//
//  EmptyStateView.swift
//  Purpose: Reusable empty state with icon, message, and a primary CTA button
//  Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2026-04-03.
//

import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let subtitle: String
    let buttonLabel: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 72, weight: .thin))
                    .foregroundStyle(.secondary)
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
            Button(action: action) {
                Text(buttonLabel)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Previews

#Preview("No nearby spots") {
    EmptyStateView(
        systemImage: "ring",
        title: "No nearby spots",
        subtitle: "Start by adding a curated list",
        buttonLabel: "Add a curated list",
        action: {}
    )
}

#Preview("Location disabled") {
    EmptyStateView(
        systemImage: "location.slash.fill",
        title: "Location Access disabled",
        subtitle: "In order for Spots to work, enable Location Access",
        buttonLabel: "iOS Settings",
        action: {}
    )
}
