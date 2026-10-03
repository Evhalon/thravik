import Foundation
import Testing
import RedentKit
@testable import RedentSync

struct SupabaseSyncTransportTests {
    private func configuration() throws -> SupabaseConfiguration {
        let url = try #require(URL(string: "https://example.supabase.co"))
        let callback = try #require(URL(string: "redent://account/callback"))
        return try SupabaseConfiguration(supabaseURL: url, publishableKey: "sb_publishable_test", callbackURL: callback)
    }

    private func session() -> AccountSession {
        AccountSession(accountID: UUID(), accessToken: "access", refreshToken: "refresh", expiresAt: .distantFuture)
    }

    @Test func acceptedResponseMatchesOriginalMutation() async throws {
        let session = session()
        let mutation = SyncMutation(identity: SyncRecordIdentity(accountID: session.accountID, collection: "spaces",
                                                                  recordID: UUID()), expectedRevision: 0,
                                     encryptedPayload: Data(repeating: 7, count: 40))
        let transport = SupabaseSyncTransport(configuration: try configuration(), transport: RPCTransportFake())
        let result = try await transport.push(mutation, session: session)
        #expect(result.mutation == mutation)
        #expect(result.revision == 1)
        #expect(result.cursor == 1)
    }

    @Test func conflictIsTypedAndWrongAccountNeverSends() async throws {
        let session = session()
        let mutation = SyncMutation(identity: SyncRecordIdentity(accountID: session.accountID, collection: "spaces",
                                                                  recordID: UUID()), expectedRevision: 0,
                                     encryptedPayload: Data(repeating: 7, count: 40))
        let transport = SupabaseSyncTransport(configuration: try configuration(), transport: RPCTransportFake(conflict: true))
        await #expect(throws: SyncError.revisionConflict) { try await transport.push(mutation, session: session) }
        let other = self.session()
        await #expect(throws: SyncError.accountMismatch) { try await transport.push(mutation, session: other) }
    }

    @Test func quotaIsNotReportedAsTransientFailure() async throws {
        let transport = SupabaseSyncTransport(configuration: try configuration(),
                                              transport: RPCTransportFake(quota: true))
        await #expect(throws: SyncError.quotaExceeded) { try await transport.pull(after: 0, session: session()) }
    }

    @Test func emptyPageDoesNotAdvanceCursor() async throws {
        let transport = SupabaseSyncTransport(configuration: try configuration(), transport: RPCTransportFake())
        let page = try await transport.pull(after: 42, session: session())
        #expect(page.nextCursor == 42)
        #expect(!page.hasMore)
        #expect(page.records.isEmpty)
    }
}

private struct RPCTransportFake: SupabaseHTTPTransport {
    var conflict = false
    var quota = false
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let url = try #require(request.url)
        #expect(request.value(forHTTPHeaderField: "apikey") == "sb_publishable_test")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer access")
        var data = Data("[]".utf8)
        if url.lastPathComponent == "sync_push" {
            let body = try #require(request.httpBody)
            let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
            var result = try #require(object["request"] as? [String: Any])
            result["status"] = conflict ? "conflict" : "accepted"
            result["revision"] = 1
            result["cursor"] = 1
            data = try JSONSerialization.data(withJSONObject: result)
        }
        if quota { data = Data("{\"message\":\"foundation_quota_reached\"}".utf8) }
        let response = try #require(HTTPURLResponse(url: url, statusCode: quota ? 500 : 200, httpVersion: nil, headerFields: nil))
        return (data, response)
    }
}
