import SwiftUI

// MARK: - Design Tokens
// Extracted from Figma designs for Dérive app
// Following Apple Human Interface Guidelines

// MARK: - Colors
// iOS 26 Liquid Glass - Adaptive colors with automatic dark mode support

import UIKit

extension Color {

    // MARK: Labels - Adaptive

    /// Primary label color - adapts to light/dark mode
    static let labelPrimary = Color(uiColor: .label)

    /// Secondary label color - adapts to light/dark mode
    static let labelSecondary = Color(uiColor: .secondaryLabel)

    /// Tertiary label color - adapts to light/dark mode
    static let labelTertiary = Color(uiColor: .tertiaryLabel)

    /// Quaternary label color - adapts to light/dark mode
    static let labelQuaternary = Color(uiColor: .quaternaryLabel)

    // MARK: Labels - Vibrant (for glass surfaces)

    /// Vibrant primary label - for use on glass/blur backgrounds
    static let labelVibrantPrimary = Color(uiColor: .label)

    /// Vibrant controls primary - for interactive elements on glass
    static let labelVibrantControlsPrimary = Color(uiColor: .secondaryLabel)

    // MARK: Accents

    /// Blue accent color - system tint
    static let accentBlue = Color.accentColor

    // MARK: Backgrounds (Grouped) - Adaptive

    /// Primary grouped background - adapts to light/dark mode
    static let backgroundGroupedPrimary = Color(uiColor: .systemGroupedBackground)

    /// Secondary grouped background - adapts to light/dark mode
    static let backgroundGroupedSecondary = Color(uiColor: .secondarySystemGroupedBackground)

    /// Tertiary grouped background - adapts to light/dark mode
    static let backgroundGroupedTertiary = Color(uiColor: .tertiarySystemGroupedBackground)

    // MARK: Fills - Adaptive

    /// Primary fill - adapts to light/dark mode
    static let fillPrimary = Color(uiColor: .systemFill)

    /// Secondary fill - adapts to light/dark mode
    static let fillSecondary = Color(uiColor: .secondarySystemFill)

    /// Tertiary fill - adapts to light/dark mode
    static let fillTertiary = Color(uiColor: .tertiarySystemFill)

    /// Vibrant tertiary fill - for glass surfaces
    static let fillVibrantTertiary = Color(uiColor: .tertiarySystemFill)

    // MARK: Separators - Adaptive

    /// Vibrant separator - adapts to light/dark mode
    static let separatorVibrant = Color(uiColor: .separator)

    /// Opaque separator - adapts to light/dark mode
    static let separatorOpaque = Color(uiColor: .opaqueSeparator)

    // MARK: Hex Initializer

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography

extension Font {

    // MARK: Large Title

    /// Large Title Emphasized - SF Pro Bold 34pt
    /// Line height: 41, Letter spacing: 0.4
    static let largeTitleEmphasized = Font.system(size: 34, weight: .bold)

    // MARK: Title

    /// Title 1 - SF Pro Regular 28pt
    static let title1 = Font.system(size: 28, weight: .regular)

    /// Title 2 - SF Pro Regular 22pt
    static let title2 = Font.system(size: 22, weight: .regular)

    /// Title 3 - SF Pro Regular 20pt
    static let title3 = Font.system(size: 20, weight: .regular)

    // MARK: Headline

    /// Headline Regular - SF Pro Semibold 17pt
    /// Line height: 22, Letter spacing: -0.43
    static let headlineRegular = Font.system(size: 17, weight: .semibold)

    // MARK: Body

    /// Body Emphasized - SF Pro Semibold 17pt
    /// Line height: 22, Letter spacing: -0.43
    static let bodyEmphasized = Font.system(size: 17, weight: .semibold)

    /// Body Regular - SF Pro Regular 17pt
    /// Line height: 22, Letter spacing: -0.43
    static let bodyRegular = Font.system(size: 17, weight: .regular)

    // MARK: Subheadline

    /// Subheadline Regular - SF Pro Regular 15pt
    /// Line height: 20, Letter spacing: -0.23
    static let subheadlineRegular = Font.system(size: 15, weight: .regular)

    /// Subheadline Emphasized - SF Pro Medium 15pt
    static let subheadlineEmphasized = Font.system(size: 15, weight: .medium)

    // MARK: Footnote

    /// Footnote Regular - SF Pro Regular 13pt
    static let footnoteRegular = Font.system(size: 13, weight: .regular)

    // MARK: Caption

    /// Caption 1 - SF Pro Regular 12pt
    static let caption1 = Font.system(size: 12, weight: .regular)

    /// Caption 2 - SF Pro Regular 11pt
    static let caption2 = Font.system(size: 11, weight: .regular)

    // MARK: Tab Bar

    /// Tab bar label - SF Pro Medium 10pt
    static let tabBarLabel = Font.system(size: 10, weight: .medium)

    /// Tab bar label selected - SF Pro Semibold 10pt
    static let tabBarLabelSelected = Font.system(size: 10, weight: .semibold)
}

// MARK: - Spacing

enum Spacing {
    /// 4pt
    static let xxSmall: CGFloat = 4
    /// 8pt
    static let xSmall: CGFloat = 8
    /// 10pt
    static let small: CGFloat = 10
    /// 16pt - Standard horizontal padding
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
    /// 10pt - Small elements
    static let small: CGFloat = 10
    /// 14pt - Medium elements (buttons)
    static let medium: CGFloat = 14
    /// 26pt - Grouped cards
    static let large: CGFloat = 26
    /// 44pt - Screen corners (matches device)
    static let screen: CGFloat = 44
    /// 100pt - Pill shape (tab bar background)
    static let pill: CGFloat = 100
}

// MARK: - Row Heights

enum RowHeight {
    /// 44pt - Standard row height
    static let standard: CGFloat = 44
    /// 68pt - Row with subtitle
    static let withSubtitle: CGFloat = 68
    /// 56pt - Tab bar button
    static let tabBarButton: CGFloat = 56
}

// MARK: - Icon Sizes

enum IconSize {
    /// 17pt - Inline icons (SF Symbols)
    static let inline: CGFloat = 17
    /// 19pt - Navigation icons
    static let navigation: CGFloat = 19
    /// 22pt - Info button
    static let info: CGFloat = 22
    /// 28pt - Tab bar icons
    static let tabBar: CGFloat = 28
}

// MARK: - Effects

enum Effects {
    /// Scroll edge blur radius - 10pt
    static let scrollEdgeBlurRadius: CGFloat = 10
    /// Background blur radius - 20pt
    static let backgroundBlurRadius: CGFloat = 20
    /// Tab bar blur radius - 50pt
    static let tabBarBlurRadius: CGFloat = 50
}

// MARK: - Preview

#Preview("Colors") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                Text("Labels")
                    .font(.headlineRegular)
                HStack {
                    ColorSwatch(color: .labelPrimary, name: "Primary")
                    ColorSwatch(color: .labelSecondary, name: "Secondary")
                    ColorSwatch(color: .labelTertiary, name: "Tertiary")
                }
            }

            Group {
                Text("Accents")
                    .font(.headlineRegular)
                HStack {
                    ColorSwatch(color: .accentBlue, name: "Blue")
                }
            }

            Group {
                Text("Backgrounds")
                    .font(.headlineRegular)
                HStack {
                    ColorSwatch(color: .backgroundGroupedPrimary, name: "Primary")
                    ColorSwatch(color: .backgroundGroupedSecondary, name: "Secondary")
                }
            }

            Group {
                Text("Separators")
                    .font(.headlineRegular)
                HStack {
                    ColorSwatch(color: .separatorVibrant, name: "Vibrant")
                    ColorSwatch(color: .separatorOpaque, name: "Opaque")
                }
            }
        }
        .padding()
    }
}

#Preview("Typography") {
    VStack(alignment: .leading, spacing: 12) {
        Text("Large Title Emphasized")
            .font(.largeTitleEmphasized)
        Text("Headline Regular")
            .font(.headlineRegular)
        Text("Body Emphasized")
            .font(.bodyEmphasized)
        Text("Body Regular")
            .font(.bodyRegular)
        Text("Subheadline Regular")
            .font(.subheadlineRegular)
        Text("Footnote Regular")
            .font(.footnoteRegular)
    }
    .padding()
}

// MARK: - Preview Helpers

private struct ColorSwatch: View {
    let color: Color
    let name: String

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 60, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.separatorOpaque, lineWidth: 0.5)
                )
            Text(name)
                .font(.caption1)
                .foregroundColor(Color.labelSecondary)
        }
    }
}
