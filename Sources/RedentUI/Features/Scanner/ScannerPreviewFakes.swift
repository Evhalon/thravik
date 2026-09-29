#if DEBUG
import Foundation
import RedentKit
import SwiftUI

/// In-memory fakes so the scanner screens can be previewed without a real
/// Keychain or a running camera.
struct PreviewOTPAuthImporter: OTPAuthImporting {
    func accounts(fromScannedText text: String) throws -> [TOTPAccount] {
        [TOTPAccount(issuer: "GitHub", accountName: "octocat", secret: Data("preview-secret".utf8))]
    }
}

struct PreviewTOTPAccountStore: TOTPAccountStoring {
    func allAccounts() async throws -> [TOTPAccount] { [] }
    func accounts(for origin: Origin) async throws -> [TOTPAccount] { [] }
    func save(_ account: TOTPAccount) async throws {}
    func importAccounts(_ accounts: [TOTPAccount]) async throws -> [TOTPAccount] { accounts }
    func link(_ id: UUID, to domain: String) async throws {}
    func delete(_ id: UUID) async throws {}
}

#Preview("Authenticator import") {
    AuthenticatorImportView(
        importer: PreviewOTPAuthImporter(),
        store: PreviewTOTPAccountStore()
    )
}
#endif
