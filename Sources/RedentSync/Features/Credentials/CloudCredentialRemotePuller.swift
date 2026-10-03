import Foundation
import RedentKit

struct CloudCredentialRemotePuller {
    let configuration: CloudCredentialConfiguration

    func pullAll(session: AccountSession) async throws {
        guard session.accountID == configuration.accountID else { throw SyncError.accountMismatch }
        var hasMore = true
        while hasMore {
            try Task.checkCancellation()
            guard try await configuration.sessions.load()?.accountID == session.accountID,
                  session.expiresAt > Date() else { throw SyncError.unauthorized }
            let cursor = try await configuration.replica.cursor(accountID: session.accountID)
            let page = try await configuration.transport.pull(after: cursor, session: session)
            try Task.checkCancellation()
            try SyncPageValidation.validate(page, accountID: session.accountID, after: cursor)
            guard try await configuration.sessions.load()?.accountID == session.accountID
            else { throw SyncError.accountMismatch }
            try await configuration.replica.apply(page, accountID: session.accountID)
            hasMore = page.hasMore
        }
    }
}
