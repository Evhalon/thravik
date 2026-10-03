import Foundation
import RedentKit
@testable import RedentUI
import Testing

@MainActor
struct OnboardingDefaultBrowserChoiceTests {
    @Test func realUseChoiceRequestsOnceAndSuppressesPostSetupOffer() async {
        let manager = ChoiceBrowserManager()
        let store = ChoicePromptStore()
        let browser = makeDefaultBrowser(manager: manager, store: store)
        let onboarding = makeOnboarding()
        onboarding.finishDefaultBrowserChoice(.useThravik, using: browser)
        while browser.isWorking { await Task.yield() }
        #expect(onboarding.isComplete)
        #expect(onboarding.didFinishDefaultBrowserChoice)
        #expect(await manager.requests == 1)
        #expect(store.lastPromptedVersion == "1.0")
        #expect(!(await browser.claimOffer()))
    }

    @Test func demoChoiceDoesNotRequestOSOrWritePromptStore() async {
        let manager = ChoiceBrowserManager()
        let store = ChoicePromptStore()
        let browser = makeDefaultBrowser(manager: manager, store: store)
        let onboarding = makeOnboarding(isDemo: true)
        var writes = 0
        onboarding.onFinish = { writes += 1 }
        onboarding.finishDefaultBrowserChoice(.useThravik, using: browser)
        #expect(onboarding.lastCompletionWasDemo)
        #expect(!onboarding.didFinishDefaultBrowserChoice)
        #expect(await manager.requests == 0)
        #expect(store.writes == 0)
        #expect(writes == 0)
    }

    @Test func keepCurrentSilencesFutureOffersAndDecideLaterOnlyRecordsRelease() async {
        let keepStore = ChoicePromptStore()
        let keepBrowser = makeDefaultBrowser(manager: ChoiceBrowserManager(), store: keepStore)
        makeOnboarding().finishDefaultBrowserChoice(.keepCurrent, using: keepBrowser)
        #expect(keepStore.isSilenced)

        let laterStore = ChoicePromptStore()
        let laterBrowser = makeDefaultBrowser(manager: ChoiceBrowserManager(), store: laterStore)
        makeOnboarding().finishDefaultBrowserChoice(.decideLater, using: laterBrowser)
        #expect(!laterStore.isSilenced)
        #expect(laterStore.lastPromptedVersion == "1.0")
    }

    private func makeOnboarding(isDemo: Bool = false) -> OnboardingModel {
        let model = OnboardingModel(isComplete: isDemo)
        if isDemo { model.startDemo() }
        model.advance()
        model.displayName = "Ada"
        model.advance()
        for _ in 0..<4 { model.advance() }
        return model
    }

    private func makeDefaultBrowser(manager: ChoiceBrowserManager,
                                    store: ChoicePromptStore) -> DefaultBrowserModel {
        DefaultBrowserModel(manager: manager, store: store, installedVersion: "1.0")
    }
}

private actor ChoiceBrowserManager: DefaultBrowserManaging {
    private(set) var requests = 0
    func isDefault() async -> Bool { false }
    func makeDefault() async -> Bool { requests += 1; return true }
}

/// NSLock protects state required by the synchronous Sendable prompt-store port.
private final class ChoicePromptStore: DefaultBrowserPromptStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var version: String?
    private var silenced = false
    private var writeCount = 0

    var lastPromptedVersion: String? { lock.withLock { version } }
    var isSilenced: Bool { lock.withLock { silenced } }
    var writes: Int { lock.withLock { writeCount } }
    func recordPrompt(for version: String?) {
        lock.withLock { self.version = version; writeCount += 1 }
    }
    func silence() { lock.withLock { silenced = true; writeCount += 1 } }
}
