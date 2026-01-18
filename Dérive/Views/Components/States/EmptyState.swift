import SwiftUI

// MARK: - Empty State

/// Centered empty state message
/// Used for: "No Nearby Spots", "No updates available"
/// Design: 22px text, semibold title, medium subtitle, secondary color
struct EmptyState: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Color.labelTertiary)
                    .padding(.bottom, Spacing.small)
            }

            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color.labelSecondary)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Color.labelSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Spacing.medium)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading State

/// Centered loading indicator
/// Used for: "Checking for updates"
struct LoadingState: View {
    var message: String? = nil

    var body: some View {
        VStack(spacing: Spacing.medium) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)

            if let message {
                Text(message)
                    .font(.bodyRegular)
                    .foregroundColor(Color.labelSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview("Empty States") {
    VStack(spacing: 32) {
        EmptyState(
            title: "No Nearby Spots",
            subtitle: "Add a Curated List"
        )
        .frame(height: 200)
        .background(Color.backgroundGroupedPrimary)

        EmptyState(
            title: "No updates available",
            systemImage: "checkmark.circle"
        )
        .frame(height: 200)
        .background(Color.backgroundGroupedPrimary)
    }
}

#Preview("Loading State") {
    LoadingState(message: "Checking for updates")
        .frame(height: 200)
        .background(Color.backgroundGroupedPrimary)
}
