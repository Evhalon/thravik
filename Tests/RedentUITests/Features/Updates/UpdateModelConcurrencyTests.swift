import Foundation
import Testing
@testable import RedentKit
@testable import RedentUI

@Suite("Update install coordination")
@MainActor
struct UpdateModelConcurrencyTests {
    @Test("A second update action cannot stage the same release twice")
    func preventsDuplicateInstall() async throws {
        let installer = PausedUpdateInstaller()
        let model = UpdateModel(
            currentVersion: AppVersion("0.1.2"),
            checker: StubChecker(version: "0.1.3"),
            installer: installer,
            quit: {}
        )
        await model.check()
        guard case .available(let release) = model.phase else {
            Issue.record("expected an available release")
            return
        }

        let firstAction = Task { await model.installAndRestart(release) }
        await installer.waitUntilStarted()
        #expect(model.phase == .installing)
        await model.installAndRestart(release)
        await model.check()
        #expect(model.phase == .installing)
        #expect(await installer.stageCount == 1)

        await installer.finish()
        await firstAction.value
        #expect(model.phase == .restarting)
    }
}

private actor PausedUpdateInstaller: UpdateInstalling {
    private(set) var stageCount = 0
    private var startWaiter: CheckedContinuation<Void, Never>?
    private var stageWaiter: CheckedContinuation<Void, Error>?

    func stage(_ release: AppRelease) async throws {
        stageCount += 1
        startWaiter?.resume()
        startWaiter = nil
        try await withCheckedThrowingContinuation { stageWaiter = $0 }
    }

    func waitUntilStarted() async {
        guard stageCount == 0 else { return }
        await withCheckedContinuation { startWaiter = $0 }
    }

    func finish() {
        stageWaiter?.resume()
        stageWaiter = nil
    }
}
