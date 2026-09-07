import RedentDesign
import RedentKit
import SwiftUI

/// Named cluster header: chevron + title, matching Dia's related-tab group.
struct SidebarGroupHeader: View {
    let cluster: SidebarNode.Cluster
    let iconTab: (any BrowserTab)?
    let isSelected: Bool
    let isCollapsed: Bool
    let actions: Actions

    struct Actions {
        let onSelect: () -> Void
        let onToggle: () -> Void
    }

    var body: some View {
        HStack(spacing: Metric.tightGutter + 2) {
            title
            Spacer(minLength: 0)
            Button(action: actions.onToggle) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .rotationEffect(.degrees(isCollapsed ? -90 : 0))
            }
            .buttonStyle(.plain)
            .help(isCollapsed ? "Show related tabs" : "Hide related tabs")
        }
        .padding(.horizontal, Metric.tightGutter + 2)
        .frame(height: Metric.tabRowHeight)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                    .fill(.white.opacity(0.13))
            }
        }
        .contentShape(.rect)
        .onTapGesture(perform: actions.onSelect)
        .animation(.easeOut(duration: 0.16), value: isCollapsed)
    }

    private var title: some View {
        HStack(spacing: Metric.tightGutter + 2) {
            FaviconView(
                data: iconTab?.snapshot.faviconData,
                host: iconTab?.origin?.displayHost ?? cluster.name,
                size: 16
            )
            Text(cluster.name)
                .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium))
                .lineLimit(1)
                .foregroundStyle(isSelected ? Palette.chromeText : Palette.chromeSecondaryText)
        }
    }
}
