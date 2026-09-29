import Foundation

public struct FloatingVideoPlayback: Sendable, Equatable {
    public var elapsed: Double = 0
    public var duration: Double = 0
    public var seekStart: Double = 0
    public var seekEnd: Double = 0
    public var volume: Double = 1
    public var isMuted = false
    public var isLive = false

    public init() {}

    public var canSeek: Bool { seekStart.isFinite && seekEnd.isFinite && seekEnd > seekStart }
    public var seekRange: ClosedRange<Double> { canSeek ? seekStart...seekEnd : 0...1 }

    public func clampedTime(_ seconds: Double) -> Double? {
        guard canSeek, seconds.isFinite else { return nil }
        return min(max(seconds, seekStart), seekEnd)
    }

    public static func timestamp(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0, seconds < Double(Int.max) else { return "--:--" }
        let total = Int(seconds)
        let minutes = total / 60
        let remainder = String(format: "%02d", total % 60)
        guard minutes >= 60 else { return "\(minutes):\(remainder)" }
        return "\(minutes / 60):\(String(format: "%02d", minutes % 60)):\(remainder)"
    }
}
