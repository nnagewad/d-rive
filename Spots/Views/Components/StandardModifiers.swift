//
//  StandardModifiers.swift
//  Purpose: Reusable view modifiers for list styling and navigation titles
//  Spots
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
}
