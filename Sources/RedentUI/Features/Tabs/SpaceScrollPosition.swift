import Foundation

struct SpaceScrollPosition: Equatable, Sendable {
    let page: Int
    let pageCount: Int
    let progress: Double

    var hasOverflow: Bool { pageCount > 1 }

    init(offset: Double = 0, contentWidth: Double = 0, viewportWidth: Double = 0) {
        guard viewportWidth > 0, contentWidth > viewportWidth + 1 else {
            page = 1
            pageCount = 1
            progress = 1
            return
        }
        let maximumOffset = contentWidth - viewportWidth
        let clampedOffset = min(max(offset, 0), maximumOffset)
        pageCount = Int(ceil(contentWidth / viewportWidth))
        progress = clampedOffset / maximumOffset
        page = min(pageCount, Int((progress * Double(pageCount - 1)).rounded()) + 1)
    }
}
