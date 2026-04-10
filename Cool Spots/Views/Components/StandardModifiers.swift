//
//  StandardModifiers.swift
//  Purpose: Reusable view modifiers for list styling, navigation titles, and button styles
//  Cool Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2026-04-03.
//

import SwiftUI

extension View {
    func standardListStyle() -> some View {
        listStyle(.insetGrouped)
    }

    func largeNavigationTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
    }

    /// Applies `.glass` on iOS 26+ and `.bordered` on earlier versions.
    func glassButtonStyle() -> some View {
        modifier(GlassButtonStyleModifier())
    }

    /// Applies `.glassProminent` on iOS 26+ and `.borderedProminent` on earlier versions.
    func glassProminentButtonStyle() -> some View {
        modifier(GlassProminentButtonStyleModifier())
    }
}

// MARK: - Button style modifiers

private struct GlassButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(.bordered)
        }
    }
}

private struct GlassProminentButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}
