import Foundation
import SwiftUI

/// A pinned tile being dragged to a new place among the pins.
struct PinnedTileDrag: Equatable {
    let tabID: UUID
    /// Where the pointer took hold of the tile, from its top-left, so the tile
    /// stays under the same point of the pointer as it travels.
    let grip: CGSize
    var location: CGPoint
    var slot: Int

    /// The lifted tile's top-left in the grid.
    var origin: CGPoint {
        CGPoint(x: location.x - grip.width, y: location.y - grip.height)
    }
}

/// Lifts a pinned tile under the pointer; the other tiles slide aside as it
/// crosses them, and a release pins it in the cell left open for it.
///
/// The tile itself stays in the grid as that open cell, so the gesture
/// survives the cell moving: the pointer is measured in the grid's space.
private struct PinnedTileDragging: ViewModifier {
    let tabID: UUID
    @Binding var drag: PinnedTileDrag?
    let space: String
    /// The cell a tile whose top-left sits at a point would land in.
    let slot: (CGPoint) -> Int
    let onDrop: (Int) -> Void
    @State private var frame = CGRect.zero

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(space)) } action: { frame = $0 }
            .gesture(gesture)
    }

    private var gesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(space))
            .onChanged { value in
                var next = drag ?? PinnedTileDrag(
                    tabID: tabID,
                    grip: CGSize(
                        width: value.startLocation.x - frame.minX,
                        height: value.startLocation.y - frame.minY
                    ),
                    location: value.location,
                    slot: 0
                )
                next.location = value.location
                next.slot = slot(next.origin)
                drag = next
            }
            .onEnded { _ in
                guard let landing = drag?.slot else { return }
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    drag = nil
                    onDrop(landing)
                }
            }
    }
}

extension View {
    func pinnedTileDragging(
        _ tabID: UUID,
        drag: Binding<PinnedTileDrag?>,
        space: String,
        slot: @escaping (CGPoint) -> Int,
        onDrop: @escaping (Int) -> Void
    ) -> some View {
        modifier(PinnedTileDragging(tabID: tabID, drag: drag, space: space, slot: slot, onDrop: onDrop))
    }
}
