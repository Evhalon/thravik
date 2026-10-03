import Foundation
@testable import Redent
import RedentKit
import Testing

struct OnboardingSoundSynthesisTests {
    @Test func ambientIsQuietPCMWithSeamlessLoopAndNoClipping() {
        let wave = OnboardingSoundSynthesis.ambient()
        #expect(wave.prefix(4) == Data("RIFF".utf8))
        #expect(wave[8..<12] == Data("WAVE".utf8))
        #expect(wave.count == 44 + 12 * 24_000 * 2)
        let samples = samples(wave)
        #expect(samples.contains { $0 != 0 })
        #expect(samples.allSatisfy { abs(Int($0)) < 2_000 })
        #expect(abs(Int(samples.first ?? 0) - Int(samples.last ?? 0)) < 150)
    }

    @Test func cuesAreFiniteDistinctAndEndInSilence() {
        let cues: [OnboardingSoundCue] = [.arrival, .advance, .back, .complete]
        let waves = cues.map(OnboardingSoundSynthesis.cue)
        #expect(Set(waves).count == 4)
        for wave in waves {
            let samples = samples(wave)
            #expect(samples.contains { $0 != 0 })
            #expect(abs(Int(samples.first ?? 0)) < 10)
            #expect(abs(Int(samples.last ?? 0)) < 10)
            #expect(samples.allSatisfy { abs(Int($0)) < 12_000 })
            #expect(wave.count <= 44 + Int(1.2 * 24_000) * 2)
        }
    }

    private func samples(_ wave: Data) -> [Int16] {
        stride(from: 44, to: wave.count - 1, by: 2).map { index in
            Int16(bitPattern: UInt16(wave[index]) | UInt16(wave[index + 1]) << 8)
        }
    }
}
