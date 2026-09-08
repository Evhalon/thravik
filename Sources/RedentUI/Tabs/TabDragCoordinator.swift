import Foundation
import RedentKit
import SwiftUI

/// Live state for dragging one tab within a strip.
///
/// The pill follows the pointer. Other rows shift as the pointer crosses
/// their midpoints, so a drop never depends on hitting a row's exact frame.
@MainActor
@Observable
final class TabDragCoordinator {
    enum Axis { case vertical, horizontal }

    private let axis: Axis
    private var liftedID: UUID?
    private var travel: CGFloat = 0
    private var slot = 0
    private var originIndex = 0
    private var span: CGFloat = 0
    private var shifts: [UUID: CGFloat] = [:]
    private var frames: [UUID: CGRect] = [:]
    private var drawn: [UUID: [UUID]] = [:]
    private var frozen: [(UUID, CGRect)] = []

    init(axis: Axis) { self.axis = axis }

    /// - Parameter tabs: the tabs this row stands for. A cluster header speaks
    ///   for its whole cluster while collapsed, so hidden members travel with it.
    func track(_ id: UUID, drawing tabs: [UUID], frame: CGRect) {
        guard liftedID == nil else { return }
        frames[id] = frame
        drawn[id] = tabs
    }

    func forget(_ id: UUID) {
        guard liftedID == nil else { return }
        frames.removeValue(forKey: id)
        drawn.removeValue(forKey: id)
    }

    var isDragging: Bool { liftedID != nil }

    func isLifted(_ id: UUID) -> Bool { id == liftedID }

    func offset(for id: UUID) -> CGSize {
        if id == liftedID { return vec(travel) }
        return vec(shifts[id] ?? 0)
    }

    func follow(_ id: UUID, to value: DragGesture.Value) {
        if liftedID != id { begin(id) }
        travel = axis == .vertical ? value.translation.height : value.translation.width
    }

    func refreshSlot(_ value: DragGesture.Value) {
        guard let liftedID else { return }
        let pointer = axis == .vertical ? value.location.y : value.location.x
        let mids = frozen.map { ($0.0, axis == .vertical ? $0.1.midY : $0.1.midX) }
        let next = TabDragGeometry.slot(pointer: pointer, mids: mids, lifted: liftedID)
        guard next != slot else { return }
        slot = next
        shifts = TabDragGeometry.shifts(
            ids: frozen.map(\.0), lifted: liftedID, from: originIndex, slot: slot, span: span
        )
    }

    func drop() -> [UUID]? {
        defer { reset() }
        guard let liftedID else { return nil }
        let rows = frozen.map { drawn[$0.0] ?? [$0.0] }
        return TabDropPlacement.reordered(liftedID, afterCount: slot, in: rows)
    }

    private func begin(_ id: UUID) {
        frozen = frames.sorted { lhs, rhs in
            axis == .vertical ? lhs.value.minY < rhs.value.minY : lhs.value.minX < rhs.value.minX
        }.map { ($0.key, $0.value) }
        guard let index = frozen.firstIndex(where: { $0.0 == id }) else { return }
        liftedID = id
        originIndex = index
        span = axis == .vertical ? frozen[index].1.height : frozen[index].1.width
        slot = index
    }

    private func reset() {
        liftedID = nil
        travel = 0
        slot = 0
        originIndex = 0
        span = 0
        shifts = [:]
        frozen = []
    }

    private func vec(_ value: CGFloat) -> CGSize {
        axis == .vertical ? CGSize(width: 0, height: value) : CGSize(width: value, height: 0)
    }
}
