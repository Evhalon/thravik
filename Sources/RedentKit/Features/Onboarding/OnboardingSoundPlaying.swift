import Foundation

public protocol OnboardingSoundPlaying: Sendable {
    func start() async throws
    func play(_ cue: OnboardingSoundCue) async throws
    func setMuted(_ muted: Bool) async
    func stop() async
}

