import Foundation
import Observation
import RedentKit

@MainActor @Observable
public final class OnboardingModel {
    public enum Step: Int, CaseIterable { case welcome, profile, space, importData, account, sync, defaultBrowser }
    public enum DefaultBrowserChoice { case useThravik, keepCurrent, decideLater }

    public private(set) var step: Step = .welcome
    public private(set) var isComplete: Bool
    public private(set) var isDemo = false
    public private(set) var lastCompletionWasDemo = false
    public private(set) var didFinishDefaultBrowserChoice = false
    public private(set) var demoAccount: AccountModel?
    public var importReceipt: BrowserImportReceipt?
    public var displayName = ""
    public var purpose = "Personal"
    public var soundEnabled = true
    public private(set) var soundUnavailable = false
    @ObservationIgnored public var sound: (any OnboardingSoundPlaying)?
    @ObservationIgnored public var onSoundPreferenceChanged: ((Bool) -> Void)?
    @ObservationIgnored var soundTask: Task<Void, Never>?
    @ObservationIgnored public var onImportBrowser: (() -> Void)?
    @ObservationIgnored public var onFinish: (() -> Void)?
    @ObservationIgnored private var demoAccountFactory: (() -> AccountModel)?

    public init(isComplete: Bool) { self.isComplete = isComplete }

    public func configureDemoAccountFactory(_ factory: @escaping () -> AccountModel) {
        demoAccountFactory = factory
    }

    public var canContinue: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func resume(profile: BrowserProfile?) {
        guard !isComplete, !isDemo, step == .welcome, let profile else { return }
        displayName = profile.displayName
        purpose = profile.purpose
        step = .account
    }

    public func advance() {
        guard step != .profile || canContinue,
              let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
        playSound(.advance)
    }

    public func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
        playSound(.back)
    }

    public var profile: BrowserProfile {
        BrowserProfile(displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines), purpose: purpose)
    }

    public func startDemo() {
        guard isComplete else { return }
        step = .welcome
        displayName = ""
        purpose = "Personal"
        demoAccount = demoAccountFactory?()
        didFinishDefaultBrowserChoice = false
        isDemo = true
        isComplete = false
    }

    public func startReal() {
        step = .welcome
        displayName = ""
        purpose = "Personal"
        demoAccount = nil
        isDemo = false
        lastCompletionWasDemo = false
        didFinishDefaultBrowserChoice = false
        isComplete = false
    }

    public func finishDefaultBrowserChoice(_ choice: DefaultBrowserChoice, using defaultBrowser: DefaultBrowserModel) {
        guard step == .defaultBrowser else { return }
        guard !isDemo else { finish(); return }
        switch choice {
        case .useThravik:
            defaultBrowser.recordOnboardingPrompt()
            if !defaultBrowser.isDefault { defaultBrowser.requestDefault() }
        case .keepCurrent:
            defaultBrowser.silence()
            defaultBrowser.recordOnboardingPrompt()
        case .decideLater: defaultBrowser.recordOnboardingPrompt()
        }
        didFinishDefaultBrowserChoice = true
        finish()
    }

    public func startSound() {
        soundUnavailable = false
        let enabled = soundEnabled
        performSound { sound in
            await sound.setMuted(!enabled)
            try await sound.start()
            try await sound.play(.arrival)
        }
    }

    public func stopSound() { performSound { await $0.stop() } }

    public func toggleSound() {
        soundEnabled.toggle()
        onSoundPreferenceChanged?(soundEnabled)
        let muted = !soundEnabled
        performSound { await $0.setMuted(muted) }
    }

    private func playSound(_ cue: OnboardingSoundCue) {
        performSound { try await $0.play(cue) }
    }

    private func performSound(_ operation: @escaping @Sendable (any OnboardingSoundPlaying) async throws -> Void) {
        guard let sound else { return }
        let previous = soundTask
        soundTask = Task { [weak self] in
            await previous?.value
            do { try await operation(sound) }
            catch {
                await sound.setMuted(true)
                self?.soundUnavailable = true
            }
        }
    }

    public func finish() {
        guard !isComplete else { return }
        playSound(.complete)
        lastCompletionWasDemo = isDemo
        if !isDemo { onFinish?() }
        isDemo = false
        isComplete = true
    }
}
