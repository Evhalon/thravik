import Foundation
import RedentKit

/// In-memory doubles, so the coordinators can be exercised without the Keychain.
actor FakeCredentialStore: CredentialStoring {
    private var items: [UUID: Credential] = [:]
    private(set) var markUsedCalls: [UUID] = []

    init(_ seed: [Credential] = []) {
        for item in seed { items[item.id] = item }
    }

    func credentials(for origin: Origin, in spaceID: UUID?) async throws -> [Credential] {
        items.values
            .filter { $0.origin.matches(origin) && (spaceID == nil || $0.spaceID == spaceID) }
            .sorted { $0.useCount > $1.useCount }
    }

    func allCredentials() async throws -> [Credential] { Array(items.values) }
    func save(_ credential: Credential) async throws { items[credential.id] = credential }
    func markUsed(_ id: UUID) async throws { markUsedCalls.append(id) }
    func delete(_ id: UUID) async throws { items[id] = nil }
}

actor FakeTOTPStore: TOTPAccountStoring {
    private var items: [TOTPAccount]
    private(set) var links: [(UUID, String)] = []

    init(_ seed: [TOTPAccount] = []) { items = seed }

    func allAccounts() async throws -> [TOTPAccount] { items }

    func accounts(for origin: Origin) async throws -> [TOTPAccount] {
        items.filter { $0.issuer.lowercased() == origin.registrableDomain.split(separator: ".").first.map(String.init) }
    }
    func save(_ account: TOTPAccount) async throws { items.append(account) }
    @discardableResult
    func importAccounts(_ accounts: [TOTPAccount]) async throws -> [TOTPAccount] {
        let fresh = accounts.filter { candidate in !items.contains { $0.secret == candidate.secret } }
        items.append(contentsOf: fresh)
        return fresh
    }
    func link(_ id: UUID, to domain: String) async throws { links.append((id, domain)) }
    func delete(_ id: UUID) async throws { items.removeAll { $0.id == id } }
}

struct FakeGenerator: TOTPGenerating {
    var digits = "123456"
    func code(for account: TOTPAccount, at date: Date) throws -> TOTPCode {
        let window = Int(date.timeIntervalSince1970) / account.period
        return TOTPCode(
            digits: digits,
            validFrom: Date(timeIntervalSince1970: Double(window * account.period)),
            period: account.period
        )
    }
}

struct SilentLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}

struct FakeOTPAuthImporter: OTPAuthImporting {
    var result: [TOTPAccount] = []
    var error: OTPImportError?

    func accounts(fromScannedText text: String) throws -> [TOTPAccount] {
        if let error { throw error }
        return result
    }
}
