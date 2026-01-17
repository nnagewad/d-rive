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

/// Small pill-shaped button
/// Used for: "Update" button in headers
struct PillButton: View {
    let title: String
    var style: PillButtonStyle = .filled
    var action: () -> Void

    enum PillButtonStyle {
        case filled
        case bordered
    }

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.subheadlineEmphasized)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundColor(style == .filled ? .white : Color.accentBlue)
                .background(style == .filled ? Color.accentBlue : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.accentBlue, lineWidth: style == .bordered ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
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
