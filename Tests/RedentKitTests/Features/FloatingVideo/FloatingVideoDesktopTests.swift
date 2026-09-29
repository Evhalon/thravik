import CoreGraphics
import RedentKit
import Testing

struct FloatingVideoDesktopTests {
    private let main = CGRect(x: 0, y: 0, width: 1_440, height: 900)

    @Test("A player straddling a seam chooses the display containing its center")
    func crossesSeam() {
        let right = CGRect(x: 1_440, y: 0, width: 1_280, height: 800)
        let desktop = FloatingVideoDesktop(screens: [main, right])
        #expect(desktop.screen(for: CGRect(x: 1_200, y: 200, width: 400, height: 225)) == main)
        #expect(desktop.screen(for: CGRect(x: 1_300, y: 200, width: 400, height: 225)) == right)
    }

    @Test("Negative and vertically stacked display coordinates are preserved")
    func otherLayouts() {
        let left = CGRect(x: -1_280, y: 100, width: 1_280, height: 800)
        let above = CGRect(x: 100, y: 900, width: 1_280, height: 800)
        let desktop = FloatingVideoDesktop(screens: [main, left, above])
        #expect(desktop.screen(for: CGRect(x: -800, y: 200, width: 400, height: 225)) == left)
        #expect(desktop.screen(for: CGRect(x: 300, y: 1_000, width: 400, height: 225)) == above)
    }

    @Test("An off-desktop or gap release settles on the nearest actual display")
    func gapsAndMissingScreens() {
        let right = CGRect(x: 1_600, y: 100, width: 1_280, height: 800)
        let desktop = FloatingVideoDesktop(screens: [main, right])
        #expect(desktop.screen(for: CGRect(x: 1_400, y: 200, width: 400, height: 225)) == right)
        #expect(desktop.screen(for: CGRect(x: -3_000, y: 200, width: 400, height: 225)) == main)
        let removed = FloatingVideoDesktop(screens: [main])
        #expect(removed.screen(for: CGRect(x: 2_000, y: 200, width: 400, height: 225)) == main)
    }

    @Test("A throw can cross the display seam and remain continuous at release")
    func throwsAcrossSeam() {
        let right = CGRect(x: 1_440, y: 0, width: 1_280, height: 800)
        let frame = CGRect(x: 1_000, y: 200, width: 400, height: 225)
        let motion = FloatingVideoMotion(frame: frame, velocity: CGSize(width: 4_000, height: 0),
            screens: [main, right])
        #expect(motion.start == frame.origin)
        #expect(motion.target.x == 1_560)
        let early = motion.position(at: 0.00001)
        #expect(abs((early.x - motion.start.x) / 0.00001 - 4_000) < 1)
        #expect(right.contains(CGRect(origin: motion.target, size: frame.size)))
    }

    @Test("An off-screen release returns smoothly instead of jumping at time zero")
    func settlesWithoutJump() {
        let frame = CGRect(x: -800, y: -500, width: 400, height: 225)
        let motion = FloatingVideoMotion(frame: frame, velocity: .zero, screens: [main])
        #expect(motion.position(at: 0) == frame.origin)
        #expect(motion.position(at: 0.1).x > frame.minX)
        #expect(main.contains(CGRect(origin: motion.target, size: frame.size)))
    }

    @Test("Empty or invalid display lists leave the player in place")
    func unavailableScreens() {
        let frame = CGRect(x: 100, y: 200, width: 400, height: 225)
        let motion = FloatingVideoMotion(frame: frame, velocity: .zero, screens: [.null, .infinite, .zero])
        #expect(motion.target == frame.origin)
    }
}
