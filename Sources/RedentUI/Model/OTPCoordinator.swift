import Foundation
import Observation
import RedentKit

/// Decides when the floating one-time-code button appears, which accounts it
/// offers, and keeps their codes fresh.
@MainActor @Observable
public final class OTPCoordinator {
    public struct Suggestion: Identifiable, Sendable {
        public let account: TOTPAccount
        public var code: TOTPCode
        public var id: UUID { account.id }
    }

    public private(set) var suggestions: [Suggestion] = []
    public private(set) var origin: Origin?
    public private(set) var now: Date = .now
    public private(set) var isUnmatched = false
    public private(set) var originMatched = false
    public private(set) var identityMatched = false
    public private(set) var didFill = false
    public var pinnedAccountID: UUID?

    private let store: any TOTPAccountStoring
    private let generator: any TOTPGenerating
    private let logger: any EventLogging
    private var filledAtURL: String?

    public init(
        store: any TOTPAccountStoring,
        generator: any TOTPGenerating,
        logger: any EventLogging
    ) {
        self.store = store
        self.generator = generator
        self.logger = logger
    }

    public var isVisible: Bool { !suggestions.isEmpty }

    public var primary: Suggestion? {
        if let pinnedAccountID, let match = suggestions.first(where: { $0.id == pinnedAccountID }) {
            return match
        }
        return suggestions.first
    }

    public var shouldAutoFill: Bool {
        guard primary != nil, !didFill else { return false }
        if originMatched { return suggestions.count == 1 || identityMatched || pinnedAccountID != nil }
        return identityMatched && suggestions.count == 1
    }

    public func fieldAppeared(at origin: Origin, username: String = "") async {
        resetChallenge()
        self.origin = origin
        do {
            let loaded = try await OTPSuggestionLoader.load(from: store, origin: origin, username: username)
            apply(loaded)
            logger.debug("otp: \(suggestions.count) candidate(s) for \(origin.registrableDomain)")
        } catch {
            logger.error("otp: lookup failed — \(String(describing: error))")
        }
    }

    public func fieldDisappeared() { resetChallenge() }

    public func markFilled(at url: URL?) {
        didFill = true
        filledAtURL = url?.absoluteString
    }

    public func dismissIfPageChanged(_ url: URL?) {
        guard didFill, let filledAtURL else { return }
        if url?.absoluteString != filledAtURL { fieldDisappeared() }
    }

    public func tick(_ date: Date) {
        now = date
        guard !suggestions.isEmpty else { return }
        for index in suggestions.indices where suggestions[index].code.expiresAt <= date {
            if let refreshed = makeSuggestion(for: suggestions[index].account) {
                suggestions[index] = refreshed
            }
        }
    }

    public func remember(_ suggestion: Suggestion) async {
        guard let origin else { return }
        pinnedAccountID = suggestion.id
        isUnmatched = false
        originMatched = true
        try? await store.link(suggestion.account.id, to: origin.registrableDomain)
    }

    private func apply(_ loaded: OTPSuggestionLoader.Result) {
        originMatched = loaded.originMatched
        isUnmatched = loaded.isUnmatched
        identityMatched = loaded.identityMatched
        pinnedAccountID = loaded.pinnedAccountID
        suggestions = loaded.accounts.compactMap(makeSuggestion)
    }

    private func resetChallenge() {
        suggestions = []
        origin = nil
        pinnedAccountID = nil
        isUnmatched = false
        originMatched = false
        identityMatched = false
        didFill = false
        filledAtURL = nil
    }

    private func makeSuggestion(for account: TOTPAccount) -> Suggestion? {
        guard let code = try? generator.code(for: account, at: .now) else {
            logger.error("otp: generation failed for \(account.redactedDescription)")
            return nil
        }
        return Suggestion(account: account, code: code)
    }
}
