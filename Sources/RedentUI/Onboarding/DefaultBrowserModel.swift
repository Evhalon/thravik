import Foundation
import Observation
import RedentKit

/// The one-time offer to become the system's default browser.
///
/// Asked once per release and never again once declined for good — the rule
/// itself is `DefaultBrowserPrompt`, which is pure and tested; this type only
/// carries it to the ports.
@MainActor @Observable
public final class DefaultBrowserModel {
    public private(set) var isWorking = false
    /// Whether macOS currently hands web links to this app. Refreshed on
    /// demand — Launch Services has no change notification worth listening to.
    public private(set) var isDefault = false
    /// Set when the user answered the system's panel with a no, so the sheet
    /// can say so instead of closing as though it worked. Cleared while a new
    /// attempt is in flight: the last answer is not this one's.
    public private(set) var didFail = false

    private let manager: any DefaultBrowserManaging
    private let store: any DefaultBrowserPromptStoring
    private let installedVersion: String?

    public init(
        manager: any DefaultBrowserManaging,
        store: any DefaultBrowserPromptStoring,
        installedVersion: String?
    ) {
        self.manager = manager
        self.store = store
        self.installedVersion = installedVersion
    }

    /// Whether this launch should show the offer. Asking marks the release as
    /// asked, so a second window opening cannot raise a second sheet.
    public func claimOffer() async -> Bool {
        let input = DefaultBrowserPrompt.Input(
            installedVersion: installedVersion,
            lastPromptedVersion: store.lastPromptedVersion,
            isSilenced: store.isSilenced,
            isAlreadyDefault: await manager.isDefault()
        )
        guard DefaultBrowserPrompt.shouldOffer(input) else { return false }
        store.recordPrompt(for: installedVersion)
        return true
    }

    public func refreshStatus() async {
        isDefault = await manager.isDefault()
    }

    /// - Returns: whether the system agreed, so the caller knows to dismiss.
    public func makeDefault() async -> Bool {
        isWorking = true
        didFail = false
        defer { isWorking = false }
        let succeeded = await manager.makeDefault()
        isDefault = succeeded
        didFail = !succeeded
        return succeeded
    }

    /// "Don't ask again" — the offer never comes back, on any release.
    public func silence() {
        store.silence()
    }
}
