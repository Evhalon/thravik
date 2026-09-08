import Foundation
import Observation
import RedentKit

/// Owns the password half of autofill: what to offer on a login page, and
/// whether a submitted login is worth saving.
///
/// Nothing here ever submits a form — filling and submitting stay separate acts.
@MainActor @Observable
public final class AutofillCoordinator {
    public private(set) var suggestions: [Credential] = []
    public private(set) var origin: Origin?
    public private(set) var isLoginFormPresent = false
    public private(set) var lastUsername = ""
    public var pendingSave: CredentialSaveRequest?

    /// `internal` rather than `private`: the save-decision half lives in a
    /// sibling file to stay under the line limit, and reads these.
    let store: any CredentialStoring
    let logger: any EventLogging
    var isEnabled: Bool
    /// The profile the window is in. Logins never cross it.
    private(set) var spaceID: UUID?
    private var lastObservedOrigin: Origin??

    public init(store: any CredentialStoring, logger: any EventLogging, isEnabled: Bool = true) {
        self.store = store
        self.logger = logger
        self.isEnabled = isEnabled
    }

    public var hasSuggestions: Bool { !suggestions.isEmpty }

    public var identityHint: String {
        lastUsername.isEmpty ? (suggestions.first?.username ?? "") : lastUsername
    }
    public var shouldOfferFill: Bool { isLoginFormPresent && hasSuggestions && pendingSave == nil }

    /// Switching Space switches vaults, so anything on offer from the old one
    /// has to go before the next page can be filled.
    public func setSpace(_ id: UUID?) {
        guard spaceID != id else { return }
        spaceID = id
        suggestions = []
        pendingSave = nil
        lastObservedOrigin = nil
    }

    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled { pendingSave = nil }
    }

    /// Origin tracking only. Vault lookup waits for `loginFormAppeared` —
    /// prefetching on every navigation walked the whole Keychain and, with
    /// leftover Comet imports, popped a password dialog per item.
    public func observe(_ origin: Origin?) {
        guard lastObservedOrigin != .some(origin) else { return }
        lastObservedOrigin = .some(origin)
        guard let origin else {
            suggestions = []
            self.origin = nil
            isLoginFormPresent = false
            lastUsername = ""
            return
        }
        if self.origin != origin {
            isLoginFormPresent = false
            self.origin = origin
            suggestions = []
            lastUsername = ""
        }
    }

    public func loginFormAppeared(at origin: Origin) async {
        lastObservedOrigin = .some(origin)
        self.origin = origin
        isLoginFormPresent = true
        await refreshSuggestions(for: origin)
    }

    public func loginFormDisappeared() { isLoginFormPresent = false }

    public func pageChanged() {
        suggestions = []
        origin = nil
        isLoginFormPresent = false
        lastUsername = ""
    }

    /// Captures a username or email typed into a login field. Never logged.
    public func captureIdentity(_ username: String) {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 320 else { return }
        lastUsername = trimmed
    }

    public func credentialFilled(_ credential: Credential) async {
        isLoginFormPresent = false
        captureIdentity(credential.username)
        try? await store.markUsed(credential.id)
    }

    func refreshSuggestions(for origin: Origin) async {
        do {
            suggestions = try await store.credentials(for: origin, in: spaceID)
            logger.debug("autofill: \(suggestions.count) credential(s) for \(origin.registrableDomain)")
        } catch {
            suggestions = []
            logger.error("autofill: lookup failed — \(String(describing: error))")
        }
    }
}
