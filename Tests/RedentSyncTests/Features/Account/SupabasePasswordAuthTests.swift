import Foundation
import RedentKit
import Testing
@testable import RedentSync

struct SupabasePasswordAuthTests {
    @Test func passwordSignInUsesPasswordGrant() async throws {
        let accountID = UUID()
        let response = sessionPayload(accountID: accountID)
        let transport = PasswordRecordingTransport(payload: response)
        let auth = SupabaseAccountAuthenticator(configuration: try configuration(), transport: transport)
        let session = try await auth.signInWithPassword(email: "person@example.com", password: "password123")
        let request = try #require(await transport.recorded())
        #expect(session.accountID == accountID)
        #expect(session.email == "person@example.com")
        #expect(session.loginMethod == .email)
        #expect(request.url?.path == "/auth/v1/token")
        #expect(request.url?.query == "grant_type=password")
        #expect(body(request)["password"] as? String == "password123")
    }

    @Test func recoveryCodeCreatesPrivateRecoverySession() async throws {
        let transport = PasswordRecordingTransport(payload: sessionPayload(accountID: UUID()))
        let auth = SupabaseAccountAuthenticator(configuration: try configuration(), transport: transport)
        try await auth.requestPasswordRecovery(email: "person@example.com")
        let request = try #require(await transport.recorded())
        #expect(request.url?.path == "/auth/v1/recover")
        #expect(body(request)["email"] as? String == "person@example.com")
        _ = try await auth.verifyPasswordRecoveryCode(email: "person@example.com", code: "123456")
        let verification = try #require(await transport.recorded())
        #expect(verification.url?.path == "/auth/v1/verify")
        #expect(body(verification)["type"] as? String == "recovery")
    }

    @Test func passwordUpdateUsesRecoveryBearerAndRejectsShortPasswords() async throws {
        let recovery = AccountSession(accountID: UUID(), accessToken: "recovery-token",
                                      refreshToken: "recovery-refresh", expiresAt: .distantFuture)
        let payload = Data("{\"id\":\"\(recovery.accountID)\"}".utf8)
        let transport = PasswordRecordingTransport(payload: payload)
        let auth = SupabaseAccountAuthenticator(configuration: try configuration(), transport: transport)
        try await auth.updatePassword(session: recovery, password: "updated-password")
        let request = try #require(await transport.recorded())
        #expect(request.httpMethod == "PUT")
        #expect(request.url?.path == "/auth/v1/user")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer recovery-token")
        #expect(body(request)["password"] as? String == "updated-password")
        await #expect(throws: AccountError.invalidPassword) {
            try await auth.updatePassword(session: recovery, password: "short")
        }
    }

    @Test func passwordUpdateRejectsDifferentOrMalformedAccount() async throws {
        let recovery = AccountSession(accountID: UUID(), accessToken: "recovery-token",
                                      refreshToken: "recovery-refresh", expiresAt: .distantFuture)
        let transport = PasswordRecordingTransport(payload: Data("{\"id\":\"\(UUID())\"}".utf8))
        let auth = SupabaseAccountAuthenticator(configuration: try configuration(), transport: transport)
        await #expect(throws: AccountError.unauthorized) {
            try await auth.updatePassword(session: recovery, password: "updated-password")
        }
        let malformed = SupabaseAccountAuthenticator(configuration: try configuration(),
                                                       transport: PasswordRecordingTransport(payload: Data("{}".utf8)))
        await #expect(throws: AccountError.invalidResponse) {
            try await malformed.updatePassword(session: recovery, password: "updated-password")
        }
    }

    private func configuration() throws -> SupabaseConfiguration {
        try SupabaseConfiguration(supabaseURL: #require(URL(string: "https://example.supabase.co")),
                                  publishableKey: "sb_publishable_test",
                                  callbackURL: #require(URL(string: "redent://auth/callback")))
    }

    private func sessionPayload(accountID: UUID) -> Data {
        Data("{\"access_token\":\"access\",\"refresh_token\":\"refresh\",\"expires_in\":3600,\"user\":{\"id\":\"\(accountID)\",\"email\":\"person@example.com\",\"app_metadata\":{\"provider\":\"google\",\"providers\":[\"google\",\"email\"]}}}".utf8)
    }

    private func body(_ request: URLRequest) -> [String: Any] {
        guard let data = request.httpBody,
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        return result
    }
}

private actor PasswordRecordingTransport: SupabaseHTTPTransport {
    private let payload: Data
    private var request: URLRequest?
    init(payload: Data) { self.payload = payload }
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        self.request = request
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: 200,
                                             httpVersion: nil, headerFields: nil) else {
            throw AccountError.invalidResponse
        }
        return (payload, response)
    }
    func recorded() -> URLRequest? { request }
}
