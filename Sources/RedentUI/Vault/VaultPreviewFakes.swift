#if DEBUG
import Foundation
import RedentKit
import SwiftUI

/// In-memory fakes so the vault screens can be previewed without a real
/// Keychain.
struct PreviewCredentialStore: CredentialStoring {
    private let sample: [Credential] = [
        Credential(origin: Origin(scheme: "https", host: "github.com"), username: "octocat", password: "hunter2"),
        Credential(
            origin: Origin(scheme: "https", host: "github.com"), username: "octocat-work", password: "correcthorse"
        ),
        Credential(origin: Origin(scheme: "https", host: "example.com"), username: "jane@example.com", password: "swordfish")
    ]

    func credentials(for origin: Origin) async throws -> [Credential] {
        sample.filter { $0.origin.matches(origin) }
    }
    func allCredentials() async throws -> [Credential] { sample }
    func save(_ credential: Credential) async throws {}
    func markUsed(_ id: UUID) async throws {}
    func delete(_ id: UUID) async throws {}
}

struct PreviewVaultTOTPStore: TOTPAccountStoring {
    private let sample: [TOTPAccount] = [
        TOTPAccount(
            issuer: "GitHub", accountName: "octocat", secret: Data("preview-secret".utf8), linkedDomains: ["github.com"]
        )
    ]

    func allAccounts() async throws -> [TOTPAccount] { sample }
    func accounts(for origin: Origin) async throws -> [TOTPAccount] { sample }
    func save(_ account: TOTPAccount) async throws {}
    func importAccounts(_ accounts: [TOTPAccount]) async throws -> [TOTPAccount] { accounts }
    func link(_ id: UUID, to domain: String) async throws {}
    func delete(_ id: UUID) async throws {}
}

struct PreviewVaultTOTPGenerator: TOTPGenerating {
    func code(for account: TOTPAccount, at date: Date) throws -> TOTPCode {
        TOTPCode(digits: "654321", validFrom: date, period: account.period)
    }
}

#Preview("Vault") {
    VaultWindowView(sources: VaultSources(
        credentials: PreviewCredentialStore(),
        totp: PreviewVaultTOTPStore(),
        generator: PreviewVaultTOTPGenerator()
    ))
}
#endif
