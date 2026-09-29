import CryptoKit
import Foundation
import RedentKit

/// Accumulates TOTP accounts scanned across possibly several QR codes — Google
/// Authenticator splits large exports into multiple "batch i of n" codes, and
/// the camera route re-detects the same code on every throttled frame while
/// it stays in view.
///
/// Dedupe happens on two levels: a hash of the raw scanned text (so the same
/// code doesn't get reprocessed or double-counted) and the decoded secret (so
/// the same account reached via two different codes doesn't appear twice).
/// The raw text is hashed rather than kept, per AGENTS.md §5 — it may contain
/// a seed, and a seed never sits in a `String` for longer than parsing needs.
@MainActor
@Observable
public final class ScannedPayloadCollector {
    public enum AddOutcome: Equatable, Sendable {
        case added(Int)
        case duplicate
        case failed(String)
    }

    public private(set) var accounts: [TOTPAccount] = []
    public private(set) var scannedPayloadCount = 0

    private var seenPayloadHashes = Set<SHA256Digest>()
    private var seenSecrets = Set<Data>()
    private let importer: any OTPAuthImporting

    public init(importer: any OTPAuthImporting) {
        self.importer = importer
    }

    public var isEmpty: Bool { accounts.isEmpty }

    /// Parses `payloadText` off the main actor and merges any new accounts in.
    @discardableResult
    public func add(payloadText: String) async -> AddOutcome {
        let hash = SHA256.hash(data: Data(payloadText.utf8))
        guard !seenPayloadHashes.contains(hash) else { return .duplicate }

        let importer = self.importer
        do {
            let decoded = try await Task.detached(priority: .userInitiated) {
                try importer.accounts(fromScannedText: payloadText)
            }.value
            seenPayloadHashes.insert(hash)
            scannedPayloadCount += 1
            return .added(merge(decoded))
        } catch {
            return .failed(String(describing: error))
        }
    }

    /// Clears everything — called when the import sheet closes, so no scanned
    /// secret outlives the flow that collected it.
    public func reset() {
        accounts.removeAll()
        seenPayloadHashes.removeAll()
        seenSecrets.removeAll()
        scannedPayloadCount = 0
    }

    private func merge(_ decoded: [TOTPAccount]) -> Int {
        var addedCount = 0
        for account in decoded where !seenSecrets.contains(account.secret) {
            seenSecrets.insert(account.secret)
            accounts.append(account)
            addedCount += 1
        }
        return addedCount
    }
}
