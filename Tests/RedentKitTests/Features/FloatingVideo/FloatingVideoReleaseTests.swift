import CoreGraphics
import Foundation
import RedentKit
import Testing

struct FloatingVideoReleaseTests {
    private let initial = CGRect(x: 300, y: 200, width: 418, height: 236)
    private let resting = CGSize(width: 400, height: 225)

    @Test("The pickup shrinks linearly while preserving the translated center")
    func linearShrink() {
        let release = FloatingVideoRelease(frame: initial, restingSize: resting, lift: 8)
        for step in 0...4 {
            let fraction = Double(step) / 4
            let origin = CGPoint(x: initial.minX + 100 * fraction, y: initial.minY + 50 * fraction)
            let frame = release.frame(at: origin, elapsed: FloatingVideoRelease.duration * fraction)
            #expect(abs(frame.width - (418 - 18 * fraction)) < 0.001)
            #expect(abs(frame.height - (236 - 11 * fraction)) < 0.001)
            #expect(abs(frame.midX - (initial.midX + 100 * fraction)) < 0.001)
            #expect(abs(frame.midY - (initial.midY + 50 * fraction - 8 * fraction)) < 0.001)
        }
    }

    @Test("Shrinking cannot pause or reverse the center of a throw")
    func glideKeepsMovingDuringShrink() {
        let motion = FloatingVideoMotion(frame: initial, velocity: CGSize(width: 900, height: 300),
            screen: CGRect(x: 0, y: 0, width: 1_440, height: 900))
        let release = FloatingVideoRelease(frame: initial, restingSize: resting, lift: 8)
        var previous = initial.midX
        for step in 1...42 {
            let elapsed = Double(step) / 100
            let frame = release.frame(at: motion.position(at: elapsed), elapsed: elapsed)
            #expect(frame.midX > previous)
            previous = frame.midX
        }
        let first = release.frame(at: motion.position(at: 0.001), elapsed: 0.001)
        #expect(abs((first.midX - initial.midX) / 0.001 - 900) < 3)
    }

    @Test("Release keeps the settled size and ignores invalid time")
    func releaseEndpoints() {
        let release = FloatingVideoRelease(frame: initial, restingSize: resting, lift: 8)
        #expect(release.frame(at: initial.origin, elapsed: .nan) == initial)
        #expect(release.frame(at: initial.origin, elapsed: -1) == initial)
        let settled = release.frame(at: initial.origin, elapsed: 1)
        #expect(settled.size == resting)
        #expect(settled.midX == initial.midX)
        #expect(settled.midY == initial.midY - 8)
    }
}
