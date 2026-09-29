import Foundation
import Observation
import RedentKit

/// Owns scan accumulation and writes each valid payload to the vault as soon
/// as it decodes. A successful write flips to `outcome` so the camera can
/// tear down; `scanAgain()` brings the scanner back for the next QR.
@MainActor
@Observable
final class AuthenticatorImportModel {
    let collector: ScannedPayloadCollector
    private(set) var addedCount = 0
    private(set) var alreadyPresentCount = 0
    private(set) var outcome: AuthenticatorImportOutcome?
    private(set) var errorMessage: String?

    private let store: any TOTPAccountStoring
    private var persistedSecrets = Set<Data>()

    init(importer: any OTPAuthImporting, store: any TOTPAccountStoring) {
        self.collector = ScannedPayloadCollector(importer: importer)
        self.store = store
    }

    var isScanning: Bool { outcome == nil }

    func persistNewAccounts() async {
        let fresh = collector.accounts.filter { !persistedSecrets.contains($0.secret) }
        guard !fresh.isEmpty else { return }
        do {
            let added = try await store.importAccounts(fresh)
            for account in fresh { persistedSecrets.insert(account.secret) }
            addedCount += added.count
            alreadyPresentCount += fresh.count - added.count
            errorMessage = nil
            outcome = AuthenticatorImportOutcome(
                accounts: fresh,
                added: added.count,
                alreadyPresent: fresh.count - added.count
            )
        } catch {
            errorMessage = "Couldn't save those accounts. Try scanning again."
        }
    }

    func scanAgain() {
        collector.reset()
        outcome = nil
        errorMessage = nil
    }
}
