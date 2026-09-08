import Foundation
import Testing
@testable import RedentKit
@testable import RedentUI

@Suite("Update model")
@MainActor
struct UpdateModelTests {
    @Test("A higher published version is offered")
    func offersNewerRelease() async throws {
        let model = makeModel(installed: "0.1.2", published: "0.1.10")
        await model.check()
        guard case .available(let release) = model.phase else {
            Issue.record("expected an available release, got \(model.phase)")
            return
        }
        #expect(release.version.description == "0.1.10")
    }

    @Test("The same or an older published version is not an update")
    func staysOnCurrentRelease() async throws {
        let same = makeModel(installed: "0.1.2", published: "0.1.2")
        await same.check()
        #expect(same.phase == .upToDate)

        let older = makeModel(installed: "0.2.0", published: "0.1.9")
        await older.check()
        #expect(older.phase == .upToDate)
    }

    @Test("A build with no version number is never offered an update")
    func refusesUnversionedBuild() async throws {
        let model = UpdateModel(
            currentVersion: nil, checker: StubChecker(version: "9.9.9"),
            installer: StubInstaller(), quit: {}
        )
        await model.check()
        #expect(model.isFailed)
    }

    @Test("A failed check reports why and offers to try again")
    func surfacesCheckFailure() async throws {
        let model = UpdateModel(
            currentVersion: AppVersion("0.1.2"), checker: FailingChecker(),
            installer: StubInstaller(), quit: {}
        )
        await model.check()
        #expect(model.phase == .failed(UpdateStubError.offline.localizedDescription))
        #expect(!model.isBusy)
    }

    @Test("Quitting only happens once the update is staged")
    func quitsAfterStaging() async throws {
        let installer = StubInstaller()
        var quits = 0
        let model = UpdateModel(
            currentVersion: AppVersion("0.1.2"), checker: StubChecker(version: "0.1.3"),
            installer: installer, quit: { quits += 1 }
        )
        await model.check()
        guard case .available(let release) = model.phase else {
            Issue.record("expected an available release")
            return
        }
        await model.installAndRestart(release)
        #expect(model.phase == .restarting)
        #expect(quits == 1)
    }

    @Test("A failed install leaves the running app alone")
    func keepsRunningAppOnFailure() async throws {
        var quits = 0
        let model = UpdateModel(
            currentVersion: AppVersion("0.1.2"), checker: StubChecker(version: "0.1.3"),
            installer: FailingInstaller(), quit: { quits += 1 }
        )
        await model.check()
        guard case .available(let release) = model.phase else {
            Issue.record("expected an available release")
            return
        }
        await model.installAndRestart(release)
        #expect(model.isFailed)
        #expect(quits == 0)
    }

    private func makeModel(installed: String, published: String) -> UpdateModel {
        UpdateModel(
            currentVersion: AppVersion(installed),
            checker: StubChecker(version: published),
            installer: StubInstaller(),
            quit: {}
        )
    }
}

private extension UpdateModel {
    var isFailed: Bool {
        if case .failed = phase { return true }
        return false
    }
}
