import AVFoundation
import Foundation
import RedentKit

actor OnboardingAudio: OnboardingSoundPlaying {
    private var ambient: AVAudioPlayer?
    private var effect: AVAudioPlayer?
    private var isMuted = false
    private var isRunning = false
    private var waves: [OnboardingSoundCue: Data] = [:]

    func start() async throws {
        guard !isRunning else { return }
        isRunning = true
        guard !isMuted else { return }
        do {
            if ambient == nil {
                ambient = try AVAudioPlayer(data: OnboardingSoundSynthesis.ambient())
                ambient?.numberOfLoops = -1
            }
            ambient?.volume = 0
            guard ambient?.play() == true else { throw AudioError.unavailable }
            ambient?.setVolume(0.38, fadeDuration: 1.2)
        } catch {
            isRunning = false
            ambient = nil
            throw AudioError.unavailable
        }
    }

    func play(_ cue: OnboardingSoundCue) async throws {
        guard isRunning, !isMuted else { return }
        do {
            let wave = waves[cue] ?? OnboardingSoundSynthesis.cue(cue)
            waves[cue] = wave
            effect?.stop()
            effect = try AVAudioPlayer(data: wave)
            effect?.volume = 0.24
            guard effect?.play() == true else { throw AudioError.unavailable }
        } catch { throw AudioError.unavailable }
    }

    func setMuted(_ muted: Bool) async {
        isMuted = muted
        if muted {
            ambient?.stop()
            effect?.stop()
        } else if isRunning {
            isRunning = false
            do { try await start() } catch { }
        }
    }

    func stop() async {
        isRunning = false
        ambient?.stop()
        // Finite chimes may finish; the ambient loop never outlives onboarding.
    }

    private enum AudioError: Error { case unavailable }
}
