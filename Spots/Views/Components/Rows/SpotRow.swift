//
//  SpotRow.swift
//  Purpose: Reusable row components
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2025-12-16.
//

import SwiftUI

// MARK: - Spot Row

/// Tappable row displaying a spot name in accent colour
/// Used for: Nearby Spots list, Curated spots list
struct SpotRow: View {
    let name: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    List {
        Section {
            SpotRow(name: "Café Lomi") {}
            SpotRow(name: "Le Comptoir Général") {}
            SpotRow(name: "Boxcar Social") {}
        }
    }
}
