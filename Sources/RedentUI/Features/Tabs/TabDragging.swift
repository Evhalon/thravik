import Foundation
import RedentDesign
import RedentKit
import SwiftUI

/// Lifts a tab row under the pointer and reorders as neighbours slide aside.
///
/// The row reports its frame so the coordinator can hit-test without a system
/// drop destination, and the gesture's minimum distance keeps a plain click on
/// the tab from being read as the start of a drag.
private struct TabDragging: ViewModifier {
    let tab: any BrowserTab
    let actions: TabRowActions
    let drag: TabDragCoordinator
    let space: String
    @State private var owner = UUID()
    @State private var tearOff = TabTearOffPreview()
    /// Once the pointer leaves the strip the tab travels in `tearOff`, drawn
    /// over everything, and its row fades out of the strip it is leaving.
    @State private var isFloating = false
    /// Only the sidebar provides one; the top strip has no pinned area.
    @Environment(PinDropTarget.self) private var pinDrop: PinDropTarget?
    /// The row in the drag's space and in `.global`, so the pointer can be
    /// carried over to the pin zone, which sits outside the scroll view.
    @State private var frameInSpace = CGRect.zero
    @State private var frameInWindow = CGRect.zero

    private var lifted: Bool { drag.isLifted(tab.id) }

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(space)) } action: {
                drag.track(.tab(tab.id), owner: owner, drawing: [tab.id], frame: $0)
                if !lifted { frameInSpace = $0 }
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
                if !lifted { frameInWindow = $0 }
            }
            .onDisappear {
                drag.forget(.tab(tab.id), owner: owner)
                tearOff.hide()
            }
            .background { liftedFill }
            .scaleEffect(lifted ? 1.02 : 1)
            .shadow(color: .black.opacity(lifted ? 0.42 : 0), radius: 12, y: 4)
            .offset(drag.offset(for: .tab(tab.id)))
            .opacity(isFloating ? 0 : 1)
            .zIndex(lifted ? 1 : 0)
            .gesture(gesture)
    }

    @ViewBuilder
    private var liftedFill: some View {
        if lifted {
            RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                .fill(Palette.liftedChrome)
        }
    }

    private var gesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(space))
            .onChanged { value in
                drag.follow(tab.id, translation: value.translation)
                let floating = isOutsideWindow || !drag.contains(value.location)
                withAnimation(.easeOut(duration: 0.16)) { isFloating = floating }
                pinDrop?.refresh(pointer: inWindow(value.location))
                guard floating else {
                    tearOff.hide()
                    withAnimation(.easeInOut(duration: 0.14)) { drag.refreshSlot(pointer: value.location) }
                    return
                }
                tearOff.follow(tab, to: TabDetachZone.pointer)
            }
            .onEnded { value in
                let landing = actions.onDetach == nil ? nil : TabDetachZone.landingFrame()
                let pins = landing == nil && pinDrop?.refresh(pointer: inWindow(value.location)) == true
                let staysInStrip = drag.contains(value.location)
                pinDrop?.end()
                tearOff.hide()
                isFloating = false
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    let order = drag.drop()
                    if let landing, let detach = actions.onDetach {
                        detach(landing)
                    } else if pins {
                        actions.onTogglePin()
                    } else if staysInStrip, let order {
                        actions.onReorder?(order)
                    }
                }
            }
    }

    private var isOutsideWindow: Bool {
        actions.onDetach != nil && TabDetachZone.landingFrame() != nil
    }

    private func inWindow(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: point.x - frameInSpace.minX + frameInWindow.minX,
            y: point.y - frameInSpace.minY + frameInWindow.minY
        )
    }
}

extension View {
    func tabDragging(
        tab: any BrowserTab,
        actions: TabRowActions,
        drag: TabDragCoordinator,
        space: String
    ) -> some View {
        modifier(TabDragging(tab: tab, actions: actions, drag: drag, space: space))
    }
}
