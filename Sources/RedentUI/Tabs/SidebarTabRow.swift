import Foundation
import RedentKit
import RedentDesign
import SwiftUI

/// One tab in the vertical rail, drawn as a pill.
///
/// The selection background is a single shared shape moved with
/// `matchedGeometryEffect`, so switching tabs slides rather than blinks.
struct SidebarTabRow: View {
    let tab: any BrowserTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let actions: TabRowActions
    let drag: TabDragCoordinator
    var indent: CGFloat = 0

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: Metric.tightGutter + 2) {
            TabRowLabel(tab: tab, isSelected: isSelected)
            Spacer(minLength: 0)
            trailingAccessory
        }
        .padding(.leading, Metric.tightGutter + 2 + indent)
        .padding(.trailing, Metric.tightGutter + 2)
        .frame(height: Metric.tabRowHeight)
        .background { selectionBackground }
        .contentShape(.rect)
        .onTapGesture(perform: actions.onSelect)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.14)) { isHovering = hovering }
        }
        .tabDragging(tab: tab, actions: actions, drag: drag, space: SidebarTabList.dragSpace)
        .contextMenu { TabRowMenu(isPinned: tab.isPinned, actions: actions) }
    }

    @ViewBuilder
    private var selectionBackground: some View {
        let shape = RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
        if drag.isLifted(tab.id) {
            EmptyView()
        } else if isSelected {
            ZStack {
                shape.fill(.white.opacity(0.13))
                shape.strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.30), .white.opacity(0.06)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: Metric.hairWidth
                )
            }
            .matchedGeometryEffect(id: "tabSelection", in: namespace)
            .shadow(color: .black.opacity(0.22), radius: 7, y: 2)
        } else if isHovering && !drag.isDragging {
            shape.fill(.white.opacity(0.07))
        }
    }

    @ViewBuilder
    private var trailingAccessory: some View {
        if isHovering {
            Button(action: actions.onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundStyle(Palette.chromeSecondaryText)
                    .frame(width: 17, height: 17)
                    .background(Circle().fill(.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .transition(.scale.combined(with: .opacity))
        } else if tab.isPinned {
            Image(systemName: "pin.fill")
                .font(.system(size: 8))
                .foregroundStyle(Palette.chromeSecondaryText)
        }
    }
}
