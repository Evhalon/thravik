import Foundation
import RedentKit
import RedentDesign
import SwiftUI

/// One chip in the horizontal strip. Pinned tabs collapse to their favicon,
/// which is what makes a wall of twenty tabs still readable.
struct TopTabItem: View {
    let tab: any BrowserTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let actions: TabRowActions

    @State private var isHovering = false
    @State private var isDropTarget = false

    private var width: CGFloat? { tab.isPinned ? Metric.tabRowHeight + 6 : 184 }

    @ViewBuilder
    private var selectionBackground: some View {
        let shape = RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
        if isSelected {
            ZStack {
                shape.fill(.white.opacity(0.13))
                shape.strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.30), .white.opacity(0.06)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: Metric.hairWidth
                )
            }
            .matchedGeometryEffect(id: "topTabSelection", in: namespace)
            .shadow(color: .black.opacity(0.22), radius: 7, y: 2)
        } else if isHovering {
            shape.fill(.white.opacity(0.07))
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if tab.isPinned {
                FaviconView(data: tab.snapshot.faviconData, host: tab.origin?.displayHost, size: 15)
                    .opacity(tab.isHibernated ? 0.55 : 1)
            } else {
                TabRowLabel(tab: tab, isSelected: isSelected)
                Spacer(minLength: 0)
                if isHovering {
                    ChromeButton(systemImage: "xmark", help: "Close tab", isEnabled: true, action: actions.onClose)
                        .controlSize(.mini)
                }
            }
        }
        .padding(.horizontal, Metric.tightGutter)
        .frame(width: width, height: Metric.tabRowHeight)
        .background { selectionBackground }
        .overlay(alignment: .leading) { dropIndicator }
        .contentShape(.rect)
        .onTapGesture(perform: actions.onSelect)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { isHovering = hovering }
        }
        .tabDragging(tab: tab, actions: actions, isTargeted: $isDropTarget)
        .contextMenu { TabRowMenu(isPinned: tab.isPinned, actions: actions) }
    }

    @ViewBuilder
    private var dropIndicator: some View {
        if isDropTarget {
            Capsule().fill(Palette.accent).frame(width: 2).padding(.vertical, 4)
        }
    }
}
