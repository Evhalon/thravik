import Foundation
import RedentKit
import Testing
@testable import RedentUI

@MainActor
struct AutofillSaveFailureTests {
    @Test func failedSaveRetainsOfferAndRetryUsesSameCredentialID() async throws {
        let store = ControlledPasswordSaveStore()
        let coordinator = makeCoordinator(store)
        let requestID = coordinator.pendingSave?.id
        let first = Task { await coordinator.confirmPendingSave() }
        await store.waitForSave()
        await store.finish(PasswordStorageError.locked)
        await first.value
        #expect(coordinator.pendingSave?.id == requestID)
        #expect(coordinator.saveErrorMessage != nil)
        #expect(!coordinator.isSavingPassword)
        let retry = Task { await coordinator.confirmPendingSave() }
        await store.waitForSave()
        await store.finish()
        await retry.value
        let ids = await store.savedIDs()
        #expect(ids.count == 2)
        #expect(ids.first == ids.last)
        #expect(coordinator.pendingSave == nil)
        #expect(coordinator.saveErrorMessage == nil)
    }

    @Test func duplicateConfirmationCreatesOnlyOneWrite() async {
        let store = ControlledPasswordSaveStore()
        let coordinator = makeCoordinator(store)
        let first = Task { await coordinator.confirmPendingSave() }
        await store.waitForSave()
        await coordinator.confirmPendingSave()
        #expect(await store.savedIDs().count == 1)
        await store.finish()
        await first.value
    }

    @Test func dismissedOfferIsNotRestoredBySaveFailure() async {
        let store = ControlledPasswordSaveStore()
        let coordinator = makeCoordinator(store)
        let task = Task { await coordinator.confirmPendingSave() }
        await store.waitForSave()
        coordinator.dismissPendingSave()
        await store.finish(PasswordStorageError.unavailable)
        await task.value
        #expect(coordinator.pendingSave == nil)
        #expect(coordinator.saveErrorMessage == nil)
    }

    @Test func replacedOfferSurvivesOldSaveCompletion() async {
        let store = ControlledPasswordSaveStore()
        let coordinator = makeCoordinator(store)
        let task = Task { await coordinator.confirmPendingSave() }
        await store.waitForSave()
        coordinator.pendingSave = request(username: "other")
        let replacementID = coordinator.pendingSave?.id
        await store.finish()
        await task.value
        #expect(coordinator.pendingSave?.id == replacementID)
        #expect(coordinator.saveErrorMessage == nil)
    }

    @Test func providerChangeInvalidatesPendingOffer() async {
        let store = ControlledPasswordSaveStore()
        let coordinator = makeCoordinator(store)
        let task = Task { await coordinator.confirmPendingSave() }
        await store.waitForSave()
        await store.finish(PasswordStorageError.providerChanged)
        await task.value
        #expect(coordinator.pendingSave == nil)
        #expect(coordinator.saveErrorMessage == nil)
    }

    private func makeCoordinator(_ store: ControlledPasswordSaveStore) -> AutofillCoordinator {
        let coordinator = AutofillCoordinator(store: store, logger: SilentLogger())
        coordinator.pendingSave = request(username: "me")
        return coordinator
    }

    private func request(username: String) -> CredentialSaveRequest {
        CredentialSaveRequest(candidate: CredentialCandidate(origin: Origin(scheme: "https", host: "example.com"),
            username: username, password: "test-secret"), kind: .new, existing: nil)
    }
}
