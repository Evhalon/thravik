import Foundation
import RedentKit
import Testing
@testable import RedentSync

struct SupabaseBackendConfigurationTests {
    private func configuration() throws -> SupabaseConfiguration {
        try SupabaseConfiguration(supabaseURL: #require(URL(string: "https://example.supabase.co")),
                                  publishableKey: "sb_publishable_test",
                                  callbackURL: #require(URL(string: "redent://account/callback")))
    }

    private func session() -> AccountSession {
        AccountSession(accountID: UUID(), accessToken: "access", refreshToken: "refresh",
                       expiresAt: .distantFuture)
    }

    @Test func missingRPCMapsToBackendNotConfiguredAcrossServices() async throws {
        let configuration = try configuration()
        let transport = ResponseTransport(status: 404, payload: Self.missingRPC)
        let session = session()
        let devices = SupabaseDeviceDirectory(configuration: configuration, transport: transport)
        let recovery = SupabaseRecoveryEnvelopeStore(configuration: configuration, transport: transport)
        let sync = SupabaseSyncTransport(configuration: configuration, transport: transport)

        await #expect(throws: SyncError.backendNotConfigured) { try await devices.list(session: session) }
        await #expect(throws: SyncError.backendNotConfigured) { try await recovery.load(session: session) }
        await #expect(throws: SyncError.backendNotConfigured) { try await sync.pull(after: 0, session: session) }
    }

    @Test func validSuccessPayloadsDoNotBecomeConfigurationErrors() async throws {
        let configuration = try configuration()
        let transport = ResponseTransport(status: 200, payload: Data("[]".utf8))
        let session = session()
        let devices = SupabaseDeviceDirectory(configuration: configuration, transport: transport)
        let sync = SupabaseSyncTransport(configuration: configuration, transport: transport)
        #expect(try await devices.list(session: session).isEmpty)
        #expect(try await sync.pull(after: 0, session: session).records.isEmpty)

        let recovery = SupabaseRecoveryEnvelopeStore(
            configuration: configuration, transport: ResponseTransport(status: 200, payload: Data("null".utf8)))
        #expect(try await recovery.load(session: session) == nil)
    }

    @Test func unrelatedServerErrorRemainsUnavailable() async throws {
        let configuration = try configuration()
        let transport = ResponseTransport(status: 500, payload: Data(#"{"message":"server failure"}"#.utf8))
        let session = session()
        let devices = SupabaseDeviceDirectory(configuration: configuration, transport: transport)
        let recovery = SupabaseRecoveryEnvelopeStore(configuration: configuration, transport: transport)
        let sync = SupabaseSyncTransport(configuration: configuration, transport: transport)

        await #expect(throws: SyncError.unavailable) { try await devices.list(session: session) }
        await #expect(throws: SyncError.unavailable) { try await recovery.load(session: session) }
        await #expect(throws: SyncError.unavailable) { try await sync.pull(after: 0, session: session) }
    }

    private static let missingRPC = Data(
        #"{"code":"PGRST202","message":"Could not find the function public.sync_pull"}"#.utf8)
}

private struct ResponseTransport: SupabaseHTTPTransport {
    let status: Int
    let payload: Data

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let url = try #require(request.url)
        let response = try #require(HTTPURLResponse(url: url, statusCode: status,
                                                    httpVersion: nil, headerFields: nil))
        return (payload, response)
    }
}
