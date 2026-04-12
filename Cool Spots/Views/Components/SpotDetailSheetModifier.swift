//
//  SpotDetailSheetModifier.swift
//  Purpose: View modifier for presenting a SpotDetailSheet from any view
//  Cool Spots
//
//  Created by Claude Code and Nikin Nagewadia on 2026-04-03.
//

import SwiftUI

extension View {
    func spotDetailSheet(item: Binding<SpotData?>, onDismiss: @escaping () -> Void = {}) -> some View {
        sheet(item: item, onDismiss: onDismiss) { spot in
            SpotDetailSheet(spot: spot)
        }
    }
}
