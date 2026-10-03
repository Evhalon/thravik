import CoreGraphics
import Foundation
import Testing
@testable import RedentKit

@Suite("Download arrival path")
struct DownloadArrivalPathTests {
    private let start = CGPoint(x: 400, y: 200)
    private let end = CGPoint(x: 900, y: 40)

    @Test("The arc starts and ends on the requested points")
    func endpoints() {
        #expect(DownloadArrivalPath.point(progress: 0, from: start, to: end) == start)
        #expect(DownloadArrivalPath.point(progress: 1, from: start, to: end) == end)
        #expect(DownloadArrivalPath.point(progress: -1, from: start, to: end) == start)
        #expect(DownloadArrivalPath.point(progress: 2, from: start, to: end) == end)
        #expect(DownloadArrivalPath.point(progress: .nan, from: start, to: end) == start)
    }

    @Test("Midway sits above the straight line so the icon arcs")
    func midpointsLift() {
        let mid = DownloadArrivalPath.point(progress: 0.5, from: start, to: end)
        #expect(mid.x > start.x && mid.x < end.x)
        #expect(mid.y < (start.y + end.y) / 2)
    }

    @Test("Scale shrinks toward the button and ignores non-finite progress")
    func scaleShrinks() {
        #expect(DownloadArrivalPath.scale(progress: 0) == 1)
        #expect(DownloadArrivalPath.scale(progress: 1) == 0.52)
        #expect(DownloadArrivalPath.scale(progress: .infinity) == 1)
    }
}
