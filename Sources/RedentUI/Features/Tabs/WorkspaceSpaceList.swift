import RedentDesign
import RedentKit
import SwiftUI

/// The Spaces in their sidebar order. Dragging a row reorders them — the
/// orbs, the menu and the ⌃⌥ number shortcuts all follow this order.
///
/// A custom drag rather than `List.onMove`: on macOS the row's tap-to-switch
/// swallows the mouse-down, so the list's own reordering never starts.
struct WorkspaceSpaceList: View {
    let model: BrowserModel
    let onSelect: (BrowserSpace) -> Void
    let onCustomize: (BrowserSpace) -> Void
    @State private var liftedID: UUID?
    @State private var travel: CGFloat = 0

    private static let rowHeight: CGFloat = 44
    private static let rowSpacing: CGFloat = 4
    private static let pitch = rowHeight + rowSpacing
    /// Room for the lifted row's scale and shadow: the scroll view clips to its
    /// bounds, so the list pads its content and bleeds the frame out to match.
    private static let liftBleed: CGFloat = 14

    var body: some View {
        ScrollView {
            VStack(spacing: Self.rowSpacing) {
                ForEach(Array(spaces.enumerated()), id: \.element.id) { index, space in
                    row(space, at: index)
                }
            }
            .padding(.horizontal, Self.liftBleed)
            .padding(.vertical, Self.liftBleed + 2)
        }
        .scrollIndicators(.never)
        .padding(-Self.liftBleed)
    }

    private var spaces: [BrowserSpace] { model.tabs.session.spaces }

    private var origin: Int? { spaces.firstIndex { $0.id == liftedID } }

    private var landing: Int? {
        guard let origin else { return nil }
        return SpaceReorder.landing(origin: origin, travel: travel, pitch: Self.pitch, count: spaces.count)
    }

    private func row(_ space: BrowserSpace, at index: Int) -> some View {
        let lifted = space.id == liftedID
        return WorkspaceSpaceRow(
            space: space,
            tabCount: tabCount(space.id),
            isSelected: space.id == model.tabs.session.selectedSpaceID,
            actions: actions(for: space)
        )
        .background {
            if lifted {
                RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                    .fill(Palette.liftedChrome)
            }
        }
        .scaleEffect(lifted ? 1.02 : 1)
        .shadow(color: .black.opacity(lifted ? 0.35 : 0), radius: 10, y: 4)
        .offset(y: offset(for: index, lifted: lifted))
        .zIndex(lifted ? 1 : 0)
        .gesture(drag(space))
    }

    private func offset(for index: Int, lifted: Bool) -> CGFloat {
        if lifted { return travel }
        guard let origin, let landing else { return 0 }
        return SpaceReorder.shift(for: index, origin: origin, landing: landing, pitch: Self.pitch)
    }

    private func drag(_ space: BrowserSpace) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                if liftedID == nil { liftedID = space.id }
                withAnimation(.easeInOut(duration: 0.14)) { travel = value.translation.height }
            }
            .onEnded { _ in drop() }
    }

    private func drop() {
        let action = origin.flatMap { from in
            landing.flatMap { SpaceReorder.action(spaces: spaces, origin: from, landing: $0) }
        }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            if let action { model.execute(action) }
            liftedID = nil
            travel = 0
        }
    }

    private func actions(for space: BrowserSpace) -> WorkspaceSpaceRow.Actions {
        WorkspaceSpaceRow.Actions(
            canDelete: spaces.count > 1,
            onSelect: { onSelect(space) },
            onCustomize: { onCustomize(space) },
            onDelete: { model.execute(.deleteSpace(space.id)) }
        )
    }

    private func tabCount(_ id: UUID) -> Int {
        model.tabs.tabs.filter { $0.snapshot.spaceID == id }.count
    }
}
