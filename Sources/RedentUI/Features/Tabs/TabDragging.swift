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

    private var lifted: Bool { drag.isLifted(tab.id) }

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(space)) } action: {
                drag.track(.tab(tab.id), owner: owner, drawing: [tab.id], frame: $0)
            }
            .onDisappear { drag.forget(.tab(tab.id), owner: owner) }
            .background { liftedFill }
            .scaleEffect(lifted ? 1.02 : 1)
            .shadow(color: .black.opacity(lifted ? 0.42 : 0), radius: 12, y: 4)
            .offset(drag.offset(for: .tab(tab.id)))
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
                withAnimation(.easeInOut(duration: 0.14)) { drag.refreshSlot(pointer: value.location) }
            }
            .onEnded { _ in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    let order = drag.drop()
                    if let detach = actions.onDetach, TabDetachZone.pointerIsOutsideKeyWindow {
                        detach()
                    } else if let order {
                        actions.onReorder?(order)
                    }
                }
            }
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
