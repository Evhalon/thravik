import Foundation
import RedentKit

actor RouterCredentialStore: CredentialStoring {
    private var values: [UUID: Credential]
    private var importFailure = false

    init(_ credentials: [Credential] = []) {
        values = Dictionary(uniqueKeysWithValues: credentials.map { ($0.id, $0) })
    }

    func failImports() { importFailure = true }
    func allCredentials() -> [Credential] { Array(values.values) }
    func credentials(for origin: Origin) -> [Credential] {
        values.values.filter { $0.origin.matches(origin) }
    }
    func save(_ credential: Credential) { values[credential.id] = credential }
    func importCredentials(_ credentials: [Credential]) throws -> [Credential] {
        guard !importFailure else { throw VaultError.authenticationFailed }
        let fresh = CredentialImportDeduper.newcomers(in: credentials, alreadyHave: Array(values.values))
        for credential in fresh { values[credential.id] = credential }
        return fresh
    }
    func markUsed(_ id: UUID) throws {
        guard var credential = values[id] else { throw VaultError.itemNotFound }
        credential.useCount += 1
        values[id] = credential
    }
    func delete(_ id: UUID) { values[id] = nil }
}
