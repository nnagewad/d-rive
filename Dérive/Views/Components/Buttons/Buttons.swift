import SwiftUI

// MARK: - Primary Button

/// Full-width primary action button using native iOS styling
/// iOS 26: Uses borderedProminent style with automatic dark mode support
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
                } else {
                    Text(title)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: CornerRadius.medium))
        .controlSize(.large)
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button

/// Bordered secondary action button using native iOS styling
/// iOS 26: Uses bordered style with automatic dark mode support
struct SecondaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(title) {
            action()
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: CornerRadius.medium))
        .controlSize(.large)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pill Button

/// Small pill-shaped button using native iOS styling
/// iOS 26: Uses bordered/borderedProminent styles with capsule shape
struct PillButton: View {
    let title: String
    var style: PillButtonStyle = .filled
    var action: () -> Void

    enum PillButtonStyle {
        case filled     // Blue background, white text
        case bordered   // Blue border and text
        case glass      // Native bordered style (iOS 26 glass)
    }

    var body: some View {
        switch style {
        case .filled:
            Button(title) {
                action()
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)

        case .bordered, .glass:
            Button(title) {
                action()
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
    }
}

// MARK: - Icon Button

/// Circular icon button using native iOS styling
/// iOS 26: Uses bordered styles with circle shape
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
        switch style {
        case .plain:
            Button {
                action()
            } label: {
                Image(systemName: systemName)
            }
            .buttonStyle(.borderless)

        case .filled:
            Button {
                action()
            } label: {
                Image(systemName: systemName)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)

        case .bordered:
            Button {
                action()
            } label: {
                Image(systemName: systemName)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
        }
    }
}

// MARK: - Back Button
// Note: With native NavigationStack, this is typically not needed
// The system provides automatic back buttons

/// Navigation back button (legacy, prefer native navigation)
struct BackButton: View {
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.accentBlue)
    }
}

// MARK: - Close Button

/// Sheet close button using native iOS styling
/// iOS 26: Uses system close button appearance
struct CloseButton: View {
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.labelSecondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Link Button

/// Text link button using native iOS styling
struct LinkButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(title) {
            action()
        }
        .buttonStyle(.borderless)
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
        PillButton(title: "Update", style: .glass) {}
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

#Preview("Close & Link") {
    VStack(spacing: 16) {
        CloseButton {}
        LinkButton(title: "Update All") {}
    }
    .padding()
}
