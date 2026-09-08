import Foundation
import SwiftUI

/// Live state for dragging one tab within a strip.
///
/// Reordering used to go through `.draggable`, which hands the gesture to
/// AppKit: a translucent ghost, a copy badge and a snap-back on release — the
/// look of moving a file, not of nudging a tab. Here the pill itself follows
/// the pointer, locked to the strip's axis, and the row it would land on
/// shows the insertion line.
@MainActor
@Observable
final class TabDragCoordinator {
    enum Axis { case vertical, horizontal }

    private let axis: Axis
    private var liftedID: UUID?
    private var targetID: UUID?
    private var travel: CGFloat = 0
    /// Row frames in the strip's coordinate space, so the pointer can be
    /// resolved to a tab without a system drop destination.
    private var frames: [UUID: CGRect] = [:]

    init(axis: Axis) { self.axis = axis }

    func track(_ id: UUID, frame: CGRect) { frames[id] = frame }

    /// A row scrolled out of a lazy stack no longer has a position to hit-test.
    func forget(_ id: UUID) { frames.removeValue(forKey: id) }

    func isLifted(_ id: UUID) -> Bool { id == liftedID }
    func isTargeted(_ id: UUID) -> Bool { id == targetID }

    /// Only the lifted row moves, and only along the strip: a tab that drifts
    /// sideways off its own rail reads as a mistake, not as a drag.
    func offset(for id: UUID) -> CGSize {
        guard id == liftedID else { return .zero }
        return axis == .vertical
            ? CGSize(width: 0, height: travel)
            : CGSize(width: travel, height: 0)
    }

    func drag(_ id: UUID, to value: DragGesture.Value) {
        liftedID = id
        travel = axis == .vertical ? value.translation.height : value.translation.width
        let under = frames.first { $0.value.contains(value.location) }?.key
        targetID = under == id ? nil : under
    }

    /// The tab the pointer released over, if the drag ends somewhere useful.
    /// Clears the lift either way — a drag that lands nowhere just settles.
    func drop() -> UUID? {
        defer {
            liftedID = nil
            targetID = nil
            travel = 0
        }
        return targetID
    }
}
