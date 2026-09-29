import Foundation
import RedentKit
import Testing

struct FloatingVideoEasingTests {
    @Test("The easing curve is bounded, symmetric, and always advances")
    func smoothCurve() {
        var previous = 0.0
        for step in 0...100 {
            let fraction = Double(step) / 100
            let progress = FloatingVideoEasing.progress(fraction)
            #expect(progress >= previous && progress <= 1)
            #expect(abs(progress + FloatingVideoEasing.progress(1 - fraction) - 1) < 0.00001)
            previous = progress
        }
        #expect(FloatingVideoEasing.progress(0.05) < 0.01)
        #expect(FloatingVideoEasing.progress(0.95) > 0.99)
    }

    @Test("Out-of-range time cannot send animation outside its endpoints")
    func invalidProgress() {
        #expect(FloatingVideoEasing.progress(-1) == 0)
        #expect(FloatingVideoEasing.progress(2) == 1)
        #expect(FloatingVideoEasing.progress(.nan) == 0)
        #expect(FloatingVideoEasing.progress(.infinity) == 0)
    }
}
