import SwiftUI

// MARK: - Primary Button

/// Full-width primary action button
/// Used for: "Download", "Get Directions"
struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.bodyEmphasized)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(.white)
            .background(Color.accentBlue)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button

/// Bordered secondary action button
/// Used for: Less prominent actions
struct SecondaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.bodyEmphasized)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(Color.accentBlue)
                .background(Color.backgroundGroupedSecondary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(Color.accentBlue, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pill Button

/// Small pill-shaped button with multiple styles
/// Used for: "Updates" button in headers, action buttons
/// Design: Supports filled, bordered, and liquid glass (iOS 26) styles
struct PillButton: View {
    let title: String
    var style: PillButtonStyle = .filled
    var action: () -> Void

    enum PillButtonStyle {
        case filled     // Blue background, white text
        case bordered   // Blue border and text
        case glass      // Liquid glass effect (iOS 26)
    }

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(style == .glass ? .system(size: 17, weight: .medium) : .subheadlineEmphasized)
                .padding(.horizontal, style == .glass ? 20 : 14)
                .padding(.vertical, style == .glass ? 6 : 7)
                .foregroundColor(foregroundColor)
                .background(backgroundView)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(strokeColor, lineWidth: style == .bordered ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch style {
        case .filled: return .white
        case .bordered: return Color.accentBlue
        case .glass: return Color.labelVibrantControlsPrimary
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .filled:
            Color.accentBlue
        case .bordered:
            Color.clear
        case .glass:
            // Liquid glass effect - semi-transparent with subtle tint
            Color(white: 0.97, opacity: 0.9)
                .background(.ultraThinMaterial)
        }
    }

    private var strokeColor: Color {
        switch style {
        case .bordered: return Color.accentBlue
        default: return .clear
        }
    }
}

// MARK: - Icon Button

/// Circular icon button
/// Used for: Subscribe/add button, close button
struct IconButton: View {
    let systemName: String
    var style: IconButtonStyle = .plain
    var action: () -> Void

    enum IconButtonStyle {
        case plain      // Just the icon
        case filled     // Blue circle background
        case bordered   // Circle outline
    }

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: 30, height: 30)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(strokeColor, lineWidth: style == .bordered ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch style {
        case .plain: return Color.accentBlue
        case .filled: return .white
        case .bordered: return Color.accentBlue
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .plain: return .clear
        case .filled: return Color.accentBlue
        case .bordered: return .clear
        }
    }

    private var strokeColor: Color {
        switch style {
        case .bordered: return Color.accentBlue
        default: return .clear
        }
    }
}

// MARK: - Back Button

/// Navigation back button
/// Used for: Detail screen headers
struct BackButton: View {
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.labelPrimary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Close Button

/// Sheet close button (X)
/// Used for: Sheet headers
struct CloseButton: View {
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.labelSecondary)
                .frame(width: 30, height: 30)
                .background(Color.fillVibrantTertiary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Link Button

/// Text link button
/// Used for: "Update All", "Open" actions
struct LinkButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.bodyRegular)
                .foregroundColor(Color.accentBlue)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Primary & Secondary") {
    VStack(spacing: 16) {
        PrimaryButton(title: "Download") {}
        PrimaryButton(title: "Loading...", isLoading: true) {}
        SecondaryButton(title: "Cancel") {}
    }
    .padding()
}

#Preview("Pill Buttons") {
    HStack(spacing: 16) {
        PillButton(title: "Update", style: .filled) {}
        PillButton(title: "Update", style: .bordered) {}
    }
    .padding()
}

#Preview("Icon Buttons") {
    HStack(spacing: 16) {
        IconButton(systemName: "plus", style: .plain) {}
        IconButton(systemName: "plus", style: .filled) {}
        IconButton(systemName: "plus", style: .bordered) {}
    }
    .padding()
}

#Preview("Navigation Buttons") {
    HStack(spacing: 16) {
        BackButton {}
        Spacer()
        CloseButton {}
    }
    .padding()
}

#Preview("Link Button") {
    LinkButton(title: "Update All") {}
        .padding()
}
