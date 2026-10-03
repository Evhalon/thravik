import Foundation
import Testing
@testable import RedentKit
@testable import RedentUI

@Suite("Default browser model")
@MainActor
struct DefaultBrowserModelTests {
    /// macOS publishes the answer seconds behind the click. Waiting on it to
    /// decide the outcome is what kept the sheet open, or called a yes a no.
    @Test("Asking returns before the system has answered")
    func requestDoesNotWaitForTheAnswer() async {
        let manager = PendingManager()
        let model = makeModel(manager: manager)

        model.requestDefault()
        #expect(model.isWorking)
        #expect(!model.isDefault)

        await manager.answer(true)
        while model.isWorking { await Task.yield() }
        #expect(model.isDefault)
    }

    @Test("A second press while the panel is up asks nothing more")
    func ignoresRepeatedRequests() async {
        let manager = PendingManager()
        let model = makeModel(manager: manager)

        model.requestDefault()
        model.requestDefault()
        await manager.answer(true)
        while model.isWorking { await Task.yield() }

        #expect(await manager.requests == 1)
    }

    @Test("An onboarding choice suppresses the duplicate release offer")
    func onboardingChoiceRecordsTheReleaseWithoutRequestingDefault() async {
        let manager = PendingManager()
        let store = PromptStoreProbe()
        let model = DefaultBrowserModel(manager: manager, store: store, installedVersion: "1.0")
        model.recordOnboardingPrompt()
        #expect(!(await model.claimOffer()))
        #expect(store.lastPromptedVersion == "1.0")
        #expect(await manager.requests == 0)
    }

    private func makeModel(manager: PendingManager) -> DefaultBrowserModel {
        DefaultBrowserModel(
            manager: manager,
            store: SilentPromptStore(),
            installedVersion: "1.0"
        )
    }
}

/// NSLock protects mutable state shared by sync Sendable prompt-store methods.
private final class PromptStoreProbe: DefaultBrowserPromptStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var version: String?
    private var silenced = false

    var lastPromptedVersion: String? { lock.withLock { version } }
    var isSilenced: Bool { lock.withLock { silenced } }
    func recordPrompt(for version: String?) { lock.withLock { self.version = version } }
    func silence() { lock.withLock { silenced = true } }
}

/// Holds each switch open until the test hands it an answer, the way the
/// system panel does.
private actor PendingManager: DefaultBrowserManaging {
    private var waiting: CheckedContinuation<Bool, Never>?
    private var early: Bool?
    private(set) var requests = 0

    func isDefault() async -> Bool { false }

    func makeDefault() async -> Bool {
        requests += 1
        if let early { return early }
        return await withCheckedContinuation { waiting = $0 }
    }

    /// An answer given before the request arrives is kept for it.
    func answer(_ agreed: Bool) {
        guard let waiting else {
            early = agreed
            return
        }
        waiting.resume(returning: agreed)
        self.waiting = nil
    }
}

private struct SilentPromptStore: DefaultBrowserPromptStoring {
    var lastPromptedVersion: String? { nil }
    func recordPrompt(for version: String?) {}
    var isSilenced: Bool { false }
    func silence() {}
}
