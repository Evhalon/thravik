import Foundation
import RedentKit

struct WorkspaceSyncUploader {
    let accountID: UUID
    let replica: any AuthenticatedSyncStoring
    let transport: any SyncTransporting

    func upload(session: AccountSession) async throws {
        let pending = try await replica.pending(accountID: accountID, limit: 100)
        for mutation in pending where mutation.identity.collection == "workspace"
            || mutation.identity.collection == "device_tabs" {
            try Task.checkCancellation()
            guard mutation.identity.accountID == accountID else { throw SyncError.accountMismatch }
            let accepted = try await transport.push(mutation, session: session)
            guard accepted.mutation == mutation, accepted.revision == mutation.expectedRevision + 1,
                  accepted.cursor > 0 else { throw SyncError.invalidResponse }
            try await replica.acknowledge(accepted)
        }
    }
}
