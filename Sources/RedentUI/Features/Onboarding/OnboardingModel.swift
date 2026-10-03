import Foundation
import Observation
import RedentKit

@MainActor @Observable
public final class OnboardingModel {
    public enum Step: Int, CaseIterable {
        case welcome = 0, account = 4, sync = 5, profile = 1, space = 2, importData = 3, defaultBrowser = 6
    }
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
    private var hasExistingProfile = false

    public init(isComplete: Bool) { self.isComplete = isComplete }
    public func configureDemoAccountFactory(_ factory: @escaping () -> AccountModel) {
        demoAccountFactory = factory
    }
    public var canContinue: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    public var stepNumber: Int { (Step.allCases.firstIndex(of: step) ?? 0) + 1 }
    public func restoreSyncedProfile(_ profile: BrowserProfile?) {
        guard !isComplete, !isDemo, !hasExistingProfile,
              (step == .welcome || step == .sync || step == .profile || step == .space),
              let profile else { return }
        displayName = profile.displayName
        purpose = profile.purpose
        hasExistingProfile = true
        if step == .profile || step == .space { step = .importData }
    }
    public func advance() {
        guard step != .profile || canContinue else { return }
        let steps = Step.allCases
        guard let index = steps.firstIndex(of: step), index + 1 < steps.count else { return }
        let nextIndex = index + 1
        step = hasExistingProfile && steps[nextIndex] == .profile ? .importData : steps[nextIndex]
        playSound(.advance)
    }
    public func back() {
        let steps = Step.allCases
        guard let index = steps.firstIndex(of: step), index > 0 else { return }
        let previousIndex = index - 1
        step = hasExistingProfile && steps[previousIndex] == .space ? .sync : steps[previousIndex]
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
        hasExistingProfile = false
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
        hasExistingProfile = false
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
