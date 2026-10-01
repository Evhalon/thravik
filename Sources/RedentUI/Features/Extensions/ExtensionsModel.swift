import Foundation
import Observation
import RedentKit

/// Drives the Extensions settings pane: adding, reviewing, and managing.
///
/// Nothing is installed without the review step — `pending` holds the
/// unpacked extension and what it may access until the user confirms.
@MainActor
@Observable
public final class ExtensionsModel {
    public private(set) var installed: [InstalledExtension] = []
    public private(set) var pending: PendingExtension?
    public private(set) var isWorking = false
    /// The extension being updated, so only its row shows progress.
    public private(set) var updatingID: UUID?
    public var errorMessage: String?
    public var storeLinkText = ""
    /// Set from a Chrome Web Store page; the Settings page answers by showing
    /// this pane and starting the review there.
    public var wantsReveal = false

    private let host: any ExtensionHosting

    public init(host: any ExtensionHosting) {
        self.host = host
        host.onChange = { [weak self] in self?.refresh() }
        refresh()
    }

    public static let storeURL = URL(string: "https://chromewebstore.google.com/category/extensions")

    public var storeID: ChromeWebStoreID? { ChromeWebStoreID(storeLinkText) }

    public func addFromStoreLink() async {
        guard let id = storeID else {
            errorMessage = "Paste a Chrome Web Store link or a 32-letter extension ID."
            return
        }
        if await review(.chromeWebStore(id)) { storeLinkText = "" }
    }

    /// The page the user is on is the extension they want; Settings takes it from here.
    public func requestInstall(_ id: ChromeWebStoreID) {
        storeLinkText = id.rawValue
        wantsReveal = true
    }

    /// - Returns: whether the extension reached the review step.
    @discardableResult
    public func review(_ source: ExtensionInstallSource) async -> Bool {
        guard !isWorking else { return false }
        isWorking = true
        defer { isWorking = false }
        do {
            pending = try await host.prepare(source)
            return true
        } catch {
            errorMessage = error.message
            return false
        }
    }

    /// Takes the pending extension at once: the alert that calls this clears
    /// its own binding right after, and that must find nothing left to cancel.
    @discardableResult
    public func confirmPending() -> Task<Void, Never>? {
        guard let extensionToAdd = pending, !isWorking else { return nil }
        pending = nil
        isWorking = true
        return Task { [weak self] in
            await self?.install(extensionToAdd)
        }
    }

    public func cancelPending() {
        guard let extensionToDrop = pending else { return }
        pending = nil
        host.discard(extensionToDrop)
    }

    public func update(_ id: UUID) async {
        guard updatingID == nil else { return }
        updatingID = id
        defer { updatingID = nil }
        do {
            try await host.update(id)
        } catch {
            errorMessage = error.message
        }
    }

    public func setEnabled(_ isEnabled: Bool, for id: UUID) { host.setEnabled(isEnabled, for: id) }
    public func remove(_ id: UUID) { host.remove(id) }
    public func openOptions(for id: UUID) { host.openOptions(for: id) }
    public func hasOptionsPage(_ id: UUID) -> Bool { host.hasOptionsPage(id) }
    public func iconPNG(for id: UUID) -> Data? { host.iconPNG(for: id) }
    public func loadFailure(for id: UUID) -> String? { host.loadFailure(for: id) }
    public func unsupportedFeatures(for id: UUID) -> [String] { host.unsupportedFeatures(for: id) }

    private func install(_ extensionToAdd: PendingExtension) async {
        defer { isWorking = false }
        do {
            try await host.commit(extensionToAdd)
        } catch {
            errorMessage = error.message
        }
    }

    private func refresh() {
        installed = host.installed
    }
}
