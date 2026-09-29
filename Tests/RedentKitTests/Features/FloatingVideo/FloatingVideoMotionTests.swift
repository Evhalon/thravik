import CoreGraphics
import Foundation
import RedentKit
import Testing

struct FloatingVideoMotionTests {
    @Test("A flick carries the player in both axes and settles exactly")
    func flickProjectsVelocity() {
        let motion = FloatingVideoMotion(frame: rect(300, 200, 400, 225),
            velocity: CGSize(width: 1_500, height: 800), screen: rect(0, 0, 1_440, 900))
        #expect(motion.target.x > motion.start.x)
        #expect(motion.target.y > motion.start.y)
        #expect(motion.position(at: 0) == motion.start)
        #expect(motion.position(at: FloatingVideoMotion.duration) == motion.target)
        #expect(motion.position(at: 0.3).x > motion.start.x)
        #expect(motion.position(at: 0.3).x < motion.target.x)
    }

    @Test("Even a hard throw leaves the complete player inside the screen")
    func flingStaysOnScreen() {
        let motion = FloatingVideoMotion(frame: rect(300, 200, 400, 225),
            velocity: CGSize(width: 50_000, height: -50_000), screen: rect(0, 0, 1_440, 900))
        for step in 0...100 {
            let point = motion.position(at: Double(step) / 100)
            #expect(point.x >= 12 && point.x <= 1_028)
            #expect(point.y >= 12 && point.y <= 663)
        }
    }

    @Test("Displays to the left of the primary use their own coordinates")
    func negativeScreenOrigin() {
        let motion = FloatingVideoMotion(frame: rect(-800, 100, 400, 225),
            velocity: CGSize(width: -5_000, height: 0), screen: rect(-1_440, 0, 1_440, 900))
        #expect(motion.target.x == -1_428)
        #expect(motion.position(at: 1) == motion.target)
    }

    @Test("Invalid input velocity is treated as a stationary release")
    func invalidVelocity() {
        let motion = FloatingVideoMotion(frame: rect(300, 200, 400, 225),
            velocity: CGSize(width: CGFloat.nan, height: CGFloat.infinity), screen: rect(0, 0, 1_440, 900))
        #expect(motion.target == motion.start)
        #expect(motion.position(at: Double.nan) == motion.start)
    }

    @Test("The glide approaches its destination without reversing or overshooting")
    func glideIsMonotonic() {
        for direction in [CGFloat(-1), 1] {
            let motion = FloatingVideoMotion(frame: rect(500, 300, 400, 225),
                velocity: CGSize(width: 900 * direction, height: 600 * direction), screen: rect(0, 0, 1_440, 900))
            var previous = motion.start
            for step in 1...100 {
                let point = motion.position(at: FloatingVideoMotion.duration * Double(step) / 100)
                #expect((point.x - previous.x) * direction >= 0)
                #expect((point.y - previous.y) * direction >= 0)
                #expect((motion.target.x - point.x) * direction >= 0)
                #expect((motion.target.y - point.y) * direction >= 0)
                previous = point
            }
        }
    }

    @Test("A throw continues at release speed and decelerates instead of pausing")
    func releaseVelocityIsContinuous() {
        let motion = FloatingVideoMotion(frame: rect(500, 300, 400, 225),
            velocity: CGSize(width: 900, height: 600), screen: rect(0, 0, 1_440, 900))
        let interval = 0.00001
        let first = motion.position(at: interval)
        #expect(abs((first.x - motion.start.x) / interval - 900) < 0.1)
        #expect(abs((first.y - motion.start.y) / interval - 600) < 0.1)
        let earlyStep = motion.position(at: 0.02).x - motion.position(at: 0.01).x
        let laterStep = motion.position(at: 0.2).x - motion.position(at: 0.19).x
        #expect(earlyStep > laterStep && laterStep > 0)
    }

    private func rect(_ x: Double, _ y: Double, _ width: Double, _ height: Double) -> CGRect {
        var rect = CGRect()
        rect.origin = CGPoint(x: x, y: y)
        rect.size = CGSize(width: width, height: height)
        return rect
    }
}
