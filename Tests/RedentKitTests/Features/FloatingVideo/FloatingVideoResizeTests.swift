import CoreGraphics
import Foundation
import Testing
@testable import RedentKit

struct FloatingVideoResizeTests {
    private let screen = CGRect(x: -1_200, y: 0, width: 1_200, height: 900)
    private let frame = CGRect(x: -900, y: 300, width: 400, height: 225)

    @Test("The top left corner and video proportions survive a horizontal resize")
    func keepsAnchorAndAspect() {
        let resized = FloatingVideoResize(frame: frame, screen: screen).frame(delta: CGSize(width: 120, height: 0))
        #expect(resized.width == 520)
        #expect(resized.minX == frame.minX)
        #expect(resized.maxY == frame.maxY)
        #expect(abs(resized.width / resized.height - 16.0 / 9) < 0.001)
    }

    @Test("Dragging downward grows the player and never lets it escape its screen")
    func clampsGrowth() {
        let resizing = FloatingVideoResize(frame: frame, screen: screen)
        let resized = resizing.frame(delta: CGSize(width: 0, height: -5_000))
        #expect(resized.width > frame.width)
        #expect(resized.maxX <= screen.maxX - 12)
        #expect(resized.minY >= screen.minY + 12)
        #expect(resized.maxY == frame.maxY)
    }

    @Test("Shrinking retains enough room for the controls, including portrait video")
    func minimumSize() {
        for aspect in [0.4, 16.0 / 9, 3] {
            let initial = CGRect(x: -900, y: 100, width: 240, height: 240 / aspect)
            let resized = FloatingVideoResize(frame: initial, screen: screen)
                .frame(delta: CGSize(width: -5_000, height: 5_000))
            #expect(resized.width >= 220)
            #expect(resized.height >= 124)
            #expect(abs(resized.width / resized.height - aspect) < 0.001)
        }
    }

    @Test("Nonfinite drag deltas cannot corrupt the frame")
    func invalidDelta() {
        let resized = FloatingVideoResize(frame: frame, screen: screen)
            .frame(delta: CGSize(width: CGFloat.nan, height: CGFloat.infinity))
        #expect(resized == frame)
    }
}
