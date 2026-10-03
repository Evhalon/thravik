import Foundation
import RedentKit

public struct SupabaseSyncTransport: SyncTransporting, SyncPushAuthenticating {
    private let configuration: SupabaseConfiguration
    private let transport: any SupabaseHTTPTransport

    public init(configuration: SupabaseConfiguration,
                transport: any SupabaseHTTPTransport = URLSessionSupabaseTransport()) {
        self.configuration = configuration
        self.transport = transport
    }

    public func push(_ mutation: SyncMutation, session: AccountSession) async throws -> SyncRemoteRecord {
        try await deliver(mutation, proof: nil, session: session)
    }

    public func push(_ mutation: SyncMutation, proof: SyncDeviceProof, session: AccountSession) async throws -> SyncRemoteRecord {
        try await deliver(mutation, proof: proof, session: session)
    }

    private func deliver(_ mutation: SyncMutation, proof: SyncDeviceProof?, session: AccountSession) async throws -> SyncRemoteRecord {
        guard mutation.identity.accountID == session.accountID else { throw SyncError.accountMismatch }
        try SyncMutationValidation.validate(mutation)
        let encoded = SupabaseSyncRecord(mutation: mutation, proof: proof)
        let body = try JSONEncoder().encode(PushRequest(request: encoded))
        let data = try await send(function: "sync_push", body: body, session: session)
        if let result = try? JSONDecoder().decode(PushStatus.self, from: data), result.status == "conflict" {
            throw SyncError.revisionConflict
        }
        guard let result = try? JSONDecoder().decode(SupabaseSyncRecord.self, from: data),
              result.status == "accepted" else { throw SyncError.invalidResponse }
        let accepted = try result.record(accountID: session.accountID)
        guard accepted.mutation == mutation, accepted.revision == mutation.expectedRevision + 1,
              accepted.cursor > 0 else { throw SyncError.invalidResponse }
        return accepted
    }

    public func pull(after cursor: Int64, session: AccountSession) async throws -> SyncPage {
        guard cursor >= 0 else { throw SyncError.invalidResponse }
        let body = try JSONEncoder().encode(PullRequest(afterCursor: cursor))
        let data = try await send(function: "sync_pull", body: body, session: session)
        guard let results = try? JSONDecoder().decode([SupabaseSyncRecord].self, from: data)
        else { throw SyncError.invalidResponse }
        let records = try results.map { try $0.record(accountID: session.accountID) }
        let page = SyncPage(records: records, nextCursor: records.last?.cursor ?? cursor,
                            hasMore: records.count == 100)
        try SyncPageValidation.validate(page, accountID: session.accountID, after: cursor)
        return page
    }

    private func send(function: String, body: Data, session: AccountSession) async throws -> Data {
        let url = configuration.supabaseURL.appendingPathComponent("rest/v1/rpc/" + function)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer " + session.accessToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        let data: Data
        let response: HTTPURLResponse
        do { (data, response) = try await transport.send(request) }
        catch is CancellationError { throw CancellationError() }
        catch { throw SyncError.unavailable }
        guard data.count <= 40 * 1024 * 1024 else { throw SyncError.invalidResponse }
        if let error = SupabaseRPCFailure.error(data: data, status: response.statusCode) { throw error }
        switch response.statusCode {
        case 200..<300: return data
        case 401, 403: throw SyncError.unauthorized
        case 429: throw SyncError.rateLimited
        case 400: throw SyncError.invalidMutation
        default: throw SyncError.unavailable
        }
    }

    private struct PushRequest: Encodable { let request: SupabaseSyncRecord }
    private struct PushStatus: Decodable { let status: String }
    private struct PullRequest: Encodable {
        let afterCursor: Int64
        let pageSize = 100
        enum CodingKeys: String, CodingKey { case afterCursor = "after_cursor", pageSize = "page_size" }
    }
}
