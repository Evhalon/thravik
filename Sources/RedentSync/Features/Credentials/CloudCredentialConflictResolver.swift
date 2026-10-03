import Foundation
import RedentKit

struct CloudCredentialConflictResolver {
    let configuration: CloudCredentialConfiguration
    private let cipher = SyncMutationCipher()

    func conflicts() async throws -> [PasswordConflict] {
        let pending = try await configuration.replica.pending(accountID: configuration.accountID, limit: 10000)
        let records = try await configuration.replica.records(accountID: configuration.accountID)
        let revisions = Dictionary(records.map { ($0.mutation.identity, $0.revision) }, uniquingKeysWith: max)
        guard var key = try await configuration.keys.load(accountID: configuration.accountID)
        else { throw SyncError.unauthorized }
        defer { key.resetBytes(in: 0..<key.count) }
        var conflicts: [PasswordConflict] = []
        for mutation in pending where mutation.identity.collection == "credentials" {
            guard let revision = revisions[mutation.identity], revision != mutation.expectedRevision else { continue }
            var plaintext = try cipher.decrypt(mutation, rootKey: key)
            defer { plaintext.resetBytes(in: 0..<plaintext.count) }
            let payload = try? JSONDecoder().decode(CloudCredentialPayload.self, from: plaintext)
            let label = payload.map { "\($0.origin.displayHost) · \($0.username)" } ?? "Password eliminata"
            conflicts.append(PasswordConflict(id: mutation.identity.recordID, label: label))
        }
        return conflicts
    }

    func resolve(id: UUID, keepingLocal: Bool) async throws {
        let pending = try await configuration.replica.pending(accountID: configuration.accountID, limit: 10000)
        guard let mutation = pending.first(where: {
            $0.identity.collection == "credentials" && $0.identity.recordID == id
        }) else { throw SyncError.invalidMutation }
        let records = try await configuration.replica.records(accountID: configuration.accountID)
        guard let remote = records.first(where: { $0.mutation.identity == mutation.identity }),
              remote.revision != mutation.expectedRevision else { throw SyncError.invalidMutation }
        guard keepingLocal else {
            try await configuration.replica.replacePending(mutation, with: nil)
            return
        }
        guard var key = try await configuration.keys.load(accountID: configuration.accountID)
        else { throw SyncError.unauthorized }
        defer { key.resetBytes(in: 0..<key.count) }
        var plaintext = try cipher.decrypt(mutation, rootKey: key)
        defer { plaintext.resetBytes(in: 0..<plaintext.count) }
        let request = SyncWriteRequest(identity: mutation.identity, expectedRevision: remote.revision,
                                       plaintext: plaintext, isDeleted: mutation.isDeleted)
        let replacement = try cipher.encrypt(request, rootKey: key)
        try await configuration.replica.replacePending(mutation, with: replacement)
    }
}
