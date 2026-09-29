import RedentKit
import SwiftUI

/// Spaces laid side by side, like pages in a row. A trackpad swipe drags the
/// row under the fingers so the next Space is already in view before it is
/// chosen; letting go settles on one page.
///
/// The row loops: past the last Space the first slides in again, one page on.
/// Only the current Space and its two neighbours are built — enough to show
/// what the swipe is heading for, without a live tab list per Space.
struct SpacePager<Page: View>: View {
    let spaces: [BrowserSpace]
    let selectedID: UUID?
    var onSelect: (UUID) -> Void
    @ViewBuilder var page: (BrowserSpace) -> Page

    @State private var dragOffset: CGFloat = 0
    /// The way the row last turned, so with two Spaces the one just left
    /// slides out on the side it went.
    @State private var lastStep = 1
    /// The page in view, counted without wrapping. Pages are identified by it
    /// rather than by Space, so each keeps its place across the loop's seam.
    @State private var anchor = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                ForEach(slots) { slot in
                    page(slot.space)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .offset(x: CGFloat(slot.side) * proxy.size.width + dragOffset)
                        // A neighbour is clipped out of sight but would still
                        // take clicks and scrolls meant for the web page beside
                        // the rail, and select a tab in another Space.
                        .allowsHitTesting(slot.side == 0)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
            .contentShape(.rect)
            // A jump of several Spaces cuts straight there: sliding would drag
            // the pages in between across the rail.
            .transaction { if abs(currentPage - anchor) > 1 { $0.animation = nil } }
            .overlay {
                HorizontalSwipeCatcher(handlers: handlers(pageWidth: proxy.size.width))
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: currentPage) { _, page in anchor = page }
    }

    private var currentIndex: Int {
        spaces.firstIndex { $0.id == selectedID } ?? 0
    }

    private var currentPage: Int {
        SpacePaging.nearestPage(showing: currentIndex, from: anchor, count: spaces.count, lean: lastStep)
    }

    private var slots: [Slot] {
        let current = currentPage
        return SpacePaging.sides(count: spaces.count, lean: lean).map { side in
            let space = spaces[SpacePaging.index(ofPage: current + side, count: spaces.count)]
            return Slot(page: current + side, side: side, space: space)
        }
    }

    private var lean: Int {
        if dragOffset < 0 { return 1 }
        if dragOffset > 0 { return -1 }
        return -lastStep
    }

    private var hasPrevious: Bool { spaces.count > 1 }
    private var hasNext: Bool { spaces.count > 1 }

    private func handlers(pageWidth: CGFloat) -> SpaceSwipeHandlers {
        SpaceSwipeHandlers(
            onTravel: { swipe in
                dragOffset = CGFloat(swipe.offset(hasPrevious: hasPrevious, hasNext: hasNext))
            },
            onRelease: { swipe in
                let step = swipe.settle(pageWidth: Double(pageWidth), hasPrevious: hasPrevious, hasNext: hasNext)
                turn(by: step)
            },
            onStep: { turn(by: $0) }
        )
    }

    /// One animated change: every page's offset is recomputed against the
    /// new selection, so the row glides on from wherever the fingers left it.
    private func turn(by step: Int) {
        let next = step == 0 ? nil : SpacePaging.neighbor(of: selectedID, in: spaces.map(\.id), step: step)
        // Springing back, the neighbour must keep the side it was drawn on;
        // turning, the Space just left goes out the way the row moved.
        let side = next == nil ? -lean : step
        withAnimation(.spring(duration: 0.34, bounce: 0.08)) {
            lastStep = side
            if let next { onSelect(next) }
            dragOffset = 0
        }
    }
}

/// One page drawn by the pager.
private struct Slot: Identifiable {
    struct ID: Hashable {
        let page: Int
        let spaceID: UUID
    }

    let page: Int
    let side: Int
    let space: BrowserSpace

    var id: ID { ID(page: page, spaceID: space.id) }
}
