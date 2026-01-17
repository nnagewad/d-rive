import SwiftUI

// MARK: - Tab Item

enum TabItem: Int, CaseIterable, Identifiable {
    case nearbySpots
    case curatedLists
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .nearbySpots: return "Nearby Spots"
        case .curatedLists: return "Curated Lists"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .nearbySpots: return "mappin.and.ellipse"
        case .curatedLists: return "list.bullet"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Custom Tab Bar

/// Custom floating tab bar matching Figma design
/// Used for: Main app navigation
struct CustomTabBar: View {
    @Binding var selectedTab: TabItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.xSmall)
        .padding(.vertical, Spacing.xSmall)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
        .padding(.horizontal, Spacing.xLarge)
        .padding(.bottom, Spacing.large)
    }
}

// MARK: - Tab Bar Button

/// Individual tab bar button
struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))

                Text(tab.title)
                    .font(isSelected ? .tabBarLabelSelected : .tabBarLabel)
            }
            .foregroundColor(isSelected ? Color.accentBlue : Color.labelVibrantControlsPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: RowHeight.tabBarButton)
            .background(
                isSelected ?
                    Capsule()
                        .fill(Color.fillVibrantTertiary) :
                    nil
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Bar Container

/// Container view that includes content and floating tab bar
struct TabBarContainer<Content: View>: View {
    @Binding var selectedTab: TabItem
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .bottom) {
            content()
                .padding(.bottom, 80) // Space for tab bar

            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}

// MARK: - Previews

#Preview("Tab Bar") {
    struct PreviewWrapper: View {
        @State private var selectedTab: TabItem = .nearbySpots

        var body: some View {
            ZStack {
                Color.backgroundGroupedPrimary
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: $selectedTab)
                }
            }
        }
    }
    return PreviewWrapper()
}

#Preview("Tab Bar Container") {
    struct PreviewWrapper: View {
        @State private var selectedTab: TabItem = .curatedLists

        var body: some View {
            TabBarContainer(selectedTab: $selectedTab) {
                Color.backgroundGroupedPrimary
                    .ignoresSafeArea()
                    .overlay(
                        Text("Selected: \(selectedTab.title)")
                            .font(.headlineRegular)
                    )
            }
        }
    }
    return PreviewWrapper()
}
