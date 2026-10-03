import Foundation
import RedentKit

/// Loop frequencies complete whole cycles; the seam never introduces a click.
enum OnboardingSoundSynthesis {
    static let sampleRate = 24_000

    static func ambient() -> Data {
        wave(duration: 12) { time in
            let swell = 0.7 + 0.3 * cos(2 * .pi * time / 12)
            return swell * (tone(196, time) * 0.025 + tone(2960.0 / 12, time) * 0.018
                            + tone(3524.0 / 12, time) * 0.012)
        }
    }

    static func cue(_ cue: OnboardingSoundCue) -> Data {
        let frequencies: [Double] = switch cue {
        case .arrival: [392, 493.88, 587.33]
        case .advance: [587.33, 783.99]
        case .back: [493.88, 392]
        case .complete: [392, 493.88, 587.33, 783.99]
        }
        let duration = cue == .complete ? 1.2 : 0.65
        return wave(duration: duration) { time in
            frequencies.enumerated().reduce(0.0) { value, entry in
                let local = time - Double(entry.offset) * 0.07
                guard local >= 0 else { return value }
                let attack = min(1, local / 0.015)
                let release = min(1, (duration - time) / 0.08)
                return value + tone(entry.element, local) * attack * release * exp(-local * 7) * 0.08
            }
        }
    }

    private static func tone(_ frequency: Double, _ time: Double) -> Double {
        sin(2 * .pi * frequency * time)
    }

    private static func wave(duration: Double, sample: (Double) -> Double) -> Data {
        let frames = Int(duration * Double(sampleRate))
        let byteCount = UInt32(frames * 2)
        var data = Data("RIFF".utf8)
        append(byteCount + 36, to: &data)
        data.append(contentsOf: "WAVEfmt ".utf8)
        append(UInt32(16), to: &data)
        append(UInt16(1), to: &data)
        append(UInt16(1), to: &data)
        append(UInt32(sampleRate), to: &data)
        append(UInt32(sampleRate * 2), to: &data)
        append(UInt16(2), to: &data)
        append(UInt16(16), to: &data)
        data.append(contentsOf: "data".utf8)
        append(byteCount, to: &data)
        data.reserveCapacity(44 + Int(byteCount))
        for frame in 0..<frames {
            let amplitude = max(-1, min(1, sample(Double(frame) / Double(sampleRate))))
            append(Int16(amplitude * Double(Int16.max)), to: &data)
        }
        return data
    }

    private static func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var value = value.littleEndian
        withUnsafeBytes(of: &value) { data.append(contentsOf: $0) }
    }
}
