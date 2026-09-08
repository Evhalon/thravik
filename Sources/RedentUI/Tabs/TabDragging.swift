import Foundation
import RedentKit
import SwiftUI

/// Lifts a tab row under the pointer and reorders on release.
///
/// The row reports its frame so the coordinator can hit-test without a system
/// drop destination, and the gesture's minimum distance keeps a plain click on
/// the tab from being read as the start of a drag.
private struct TabDragging: ViewModifier {
    let tab: any BrowserTab
    let actions: TabRowActions
    let drag: TabDragCoordinator
    let space: String

    private var lifted: Bool { drag.isLifted(tab.id) }

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(space)) } action: {
                drag.track(tab.id, frame: $0)
            }
            .onDisappear { drag.forget(tab.id) }
            .scaleEffect(lifted ? 1.035 : 1)
            .shadow(color: .black.opacity(lifted ? 0.34 : 0), radius: 11, y: 3)
            .offset(drag.offset(for: tab.id))
            .zIndex(lifted ? 1 : 0)
            .gesture(gesture)
    }

    private var gesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(space))
            .onChanged { value in
                withAnimation(.easeOut(duration: 0.12)) { drag.drag(tab.id, to: value) }
            }
            .onEnded { _ in
                withAnimation(.spring(duration: 0.26)) {
                    if let target = drag.drop() { actions.onMoveOnto?(target) }
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
