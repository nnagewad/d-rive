//
//  SpotDetailSheetModifier.swift
//  Purpose: View modifier for presenting a SpotDetailSheet from any view
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2026-04-03.
//

import SwiftUI

extension View {
    func spotDetailSheet(item: Binding<SpotData?>, onClose: @escaping () -> Void) -> some View {
        sheet(item: item) { spot in
            SpotDetailSheet(spot: spot, onClose: onClose)
        }
    }
}
