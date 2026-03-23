//
//  DesignTokens.swift
//  Purpose: App-specific design tokens with no native SwiftUI equivalent
//  Dérive
//
//  Created by Claude Code and Nikin Nagewadia on 2026-03-23.
//

import SwiftUI

// MARK: - Spacing

enum Spacing {
    /// 4pt
    static let xxSmall: CGFloat = 4
    /// 8pt
    static let xSmall: CGFloat = 8
    /// 10pt
    static let small: CGFloat = 10
    /// 16pt
    static let medium: CGFloat = 16
    /// 20pt
    static let large: CGFloat = 20
    /// 24pt
    static let xLarge: CGFloat = 24
    /// 34pt
    static let xxLarge: CGFloat = 34
}

// MARK: - Corner Radius

enum CornerRadius {
    /// 26pt — grouped cards
    static let large: CGFloat = 26
}

// MARK: - Row Heights

enum RowHeight {
    /// 44pt — standard
    static let standard: CGFloat = 44
    /// 68pt — with subtitle
    static let withSubtitle: CGFloat = 68
    /// 56pt — tab bar button
    static let tabBarButton: CGFloat = 56
}

// MARK: - Icon Sizes

enum IconSize {
    /// 17pt — inline
    static let inline: CGFloat = 17
    /// 19pt — navigation
    static let navigation: CGFloat = 19
    /// 22pt — info button
    static let info: CGFloat = 22
    /// 28pt — tab bar
    static let tabBar: CGFloat = 28
}

// MARK: - Effects

enum Effects {
    /// 10pt
    static let scrollEdgeBlurRadius: CGFloat = 10
    /// 20pt
    static let backgroundBlurRadius: CGFloat = 20
    /// 50pt
    static let tabBarBlurRadius: CGFloat = 50
}
