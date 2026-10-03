import RedentKit
@testable import RedentUI
import Testing

@MainActor
struct OnboardingSoundModelTests {
    @Test func completionStopsAmbientAndPreservesFiniteChimeOrder() async {
        let sound = OnboardingSoundProbe()
        let model = OnboardingModel(isComplete: false)
        model.sound = sound
        model.startSound()
        model.advance()
        model.finish()
        model.stopSound()
        await model.soundTask?.value
        #expect(await sound.events == ["mute:false", "start", "arrival", "advance", "complete", "stop"])
    }

    @Test func failureMutesAudioWithoutBlockingSetup() async {
        let sound = OnboardingSoundProbe(fails: true)
        let model = OnboardingModel(isComplete: false)
        model.sound = sound
        model.startSound()
        await model.soundTask?.value
        #expect(model.soundUnavailable)
        #expect(await sound.events == ["mute:false", "start", "mute:true"])
        model.advance()
        #expect(model.step == .account)
        model.finish()
        #expect(model.isComplete)
        await model.soundTask?.value
    }

    @Test func mutePreferenceSurvivesDemoRestart() async {
        let sound = OnboardingSoundProbe()
        let model = OnboardingModel(isComplete: true)
        model.sound = sound
        var preferences: [Bool] = []
        model.onSoundPreferenceChanged = { preferences.append($0) }
        model.toggleSound()
        model.startDemo()
        model.startSound()
        await model.soundTask?.value
        #expect(!model.soundEnabled)
        #expect(preferences == [false])
        #expect(await sound.events.first == "mute:true")
        model.stopSound()
        await model.soundTask?.value
    }
}

private actor OnboardingSoundProbe: OnboardingSoundPlaying {
    private let fails: Bool
    private(set) var events: [String] = []

    init(fails: Bool = false) { self.fails = fails }

    func start() async throws {
        events.append("start")
        if fails { throw AudioFailure.unavailable }
    }

    func play(_ cue: OnboardingSoundCue) async throws { events.append(String(describing: cue)) }
    func setMuted(_ muted: Bool) async { events.append("mute:\(muted)") }
    func stop() async { events.append("stop") }

    private enum AudioFailure: Error { case unavailable }
}
