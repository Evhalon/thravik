import Foundation
import Testing
import RedentKit
@testable import RedentSync

struct SupabasePasswordEnvelopeStoreTests {
    @Test func loadAndImmutableCreateUseAuthenticatedRPCs() async throws {
        let session = AccountSession(accountID: UUID(), accessToken: "access", refreshToken: "refresh",
                                     expiresAt: .distantFuture)
        let envelope = try SyncPasswordCryptography().wrap(recoveryCode: recoveryCode,
                                                            password: "a long master password",
                                                            accountID: session.accountID)
        let transport = PasswordEnvelopeRPCFake(envelope: envelope)
        let store = SupabasePasswordEnvelopeStore(configuration: try configuration(), transport: transport)
        #expect(try await store.saveIfAbsent(envelope, session: session))
        #expect(try await store.load(session: session) == envelope)
        #expect(await transport.functions == ["vault_password_create", "vault_password_get"])
    }

    @Test func rejectsMalformedServerEnvelope() async throws {
        let transport = PasswordEnvelopeRPCFake(response: Data("{\"protocolVersion\":1}".utf8))
        let store = SupabasePasswordEnvelopeStore(configuration: try configuration(), transport: transport)
        let session = AccountSession(accountID: UUID(), accessToken: "access", refreshToken: "refresh",
                                     expiresAt: .distantFuture)
        await #expect(throws: SyncError.invalidResponse) { try await store.load(session: session) }
    }

    private var recoveryCode: String {
        "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef-01234567"
    }

    private func configuration() throws -> SupabaseConfiguration {
        let url = try #require(URL(string: "https://example.supabase.co"))
        let callback = try #require(URL(string: "redent://account/callback"))
        return try SupabaseConfiguration(supabaseURL: url, publishableKey: "sb_publishable_test", callbackURL: callback)
    }
}

private actor PasswordEnvelopeRPCFake: SupabaseHTTPTransport {
    private let envelope: PasswordKeyEnvelope?
    private let response: Data?
    private(set) var functions: [String] = []

    init(envelope: PasswordKeyEnvelope? = nil, response: Data? = nil) {
        self.envelope = envelope
        self.response = response
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let url = try #require(request.url)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer access")
        functions.append(url.lastPathComponent)
        let body: Data
        switch url.lastPathComponent {
        case "vault_password_get":
            body = try JSONEncoder().encode(envelope)
        case "vault_password_create":
            body = Data("true".utf8)
        default:
            body = response ?? Data("null".utf8)
        }
        let result = response ?? body
        let status = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        return (result, status)
    }
}
