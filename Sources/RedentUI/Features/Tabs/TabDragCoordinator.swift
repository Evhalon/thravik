import Foundation
import Observation
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

    /// A cluster header can share its id with its first member — automatic
    /// clusters are named after a tab — so headers and tabs are keyed apart.
    enum Row: Hashable {
        case tab(UUID)
        case header(UUID)
    }

    private let axis: Axis
    private var liftedID: UUID?
    private var travel: CGFloat = 0
    @ObservationIgnored private var slot = 0
    @ObservationIgnored private var originIndex = 0
    @ObservationIgnored private var span: CGFloat = 0
    private var shifts: [Row: CGFloat] = [:]
    @ObservationIgnored private var frames: [Row: CGRect] = [:]
    @ObservationIgnored private var drawn: [Row: [UUID]] = [:]
    @ObservationIgnored private var owners: [Row: UUID] = [:]
    @ObservationIgnored private var frozen: [(Row, CGRect)] = []

    init(axis: Axis) { self.axis = axis }

    /// - Parameter tabs: the tabs this row stands for. A cluster header speaks
    ///   for its whole cluster while collapsed, so hidden members travel with it.
    /// - Parameter owner: the view reporting. A tab that joins a group is
    ///   redrawn by a new view, and the old one's `onDisappear` can land after
    ///   the new one reported — only the latest reporter may forget the row.
    func track(_ row: Row, owner: UUID? = nil, drawing tabs: [UUID], frame: CGRect) {
        guard liftedID == nil else { return }
        frames[row] = frame
        drawn[row] = tabs
        owners[row] = owner
    }

    func forget(_ row: Row, owner: UUID? = nil) {
        guard liftedID == nil, owners[row] == owner else { return }
        frames.removeValue(forKey: row)
        drawn.removeValue(forKey: row)
        owners.removeValue(forKey: row)
    }

    var isDragging: Bool { liftedID != nil }

    func isLifted(_ id: UUID) -> Bool { id == liftedID }

    func offset(for row: Row) -> CGSize {
        if let liftedID, row == .tab(liftedID) { return vec(travel) }
        return vec(shifts[row] ?? 0)
    }

    func follow(_ id: UUID, translation: CGSize) {
        if liftedID != id { begin(id) }
        travel = axis == .vertical ? translation.height : translation.width
    }

    func refreshSlot(pointer location: CGPoint) {
        guard let liftedID else { return }
        let pointer = axis == .vertical ? location.y : location.x
        let mids = frozen.map { ($0.0, axis == .vertical ? $0.1.midY : $0.1.midX) }
        let next = TabDragGeometry.slot(pointer: pointer, mids: mids, lifted: Row.tab(liftedID))
        guard next != slot else { return }
        slot = next
        shifts = TabDragGeometry.shifts(
            ids: frozen.map(\.0), lifted: .tab(liftedID), from: originIndex, slot: slot, span: span
        )
    }

    func drop() -> [UUID]? {
        defer { reset() }
        guard let liftedID else { return nil }
        let rows = frozen.map { drawn[$0.0] ?? [] }
        return TabDropPlacement.reordered(liftedID, afterCount: slot, in: rows)
    }

    private func begin(_ id: UUID) {
        frozen = frames.sorted { lhs, rhs in
            axis == .vertical ? lhs.value.minY < rhs.value.minY : lhs.value.minX < rhs.value.minX
        }.map { ($0.key, $0.value) }
        guard let index = frozen.firstIndex(where: { $0.0 == .tab(id) }) else { return }
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
