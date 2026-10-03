import CryptoKit
import Foundation
import RedentKit
import Testing
@testable import RedentSync

struct SupabaseAccountTests {
    private func configuration() throws -> SupabaseConfiguration {
        try SupabaseConfiguration(supabaseURL: #require(URL(string: "https://example.supabase.co")),
                                  publishableKey: "sb_publishable_test",
                                  callbackURL: #require(URL(string: "redent://auth/callback")))
    }

    @Test func rejectsInsecureConfiguration() throws {
        #expect(throws: AccountError.invalidConfiguration) {
            try SupabaseConfiguration(supabaseURL: #require(URL(string: "http://example.com")),
                                      publishableKey: "public", callbackURL: #require(URL(string: "redent://auth")))
        }
    }

    @Test func emailRequestHasCorrectFormat() async throws {
        let transport = RecordingTransport(status: 200, payload: Data())
        let auth = SupabaseAccountAuthenticator(configuration: try configuration(), transport: transport)
        try await auth.requestEmailCode(email: "person@example.com")
        let request = try #require(await transport.recorded())
        #expect(request.url?.path == "/auth/v1/otp")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "apikey") == "sb_publishable_test")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        let requestData = try #require(request.httpBody)
        let body = try #require(JSONSerialization.jsonObject(with: requestData) as? [String: Any])
        #expect(body["email"] as? String == "person@example.com")
        #expect(body["create_user"] as? Bool == true)
    }

    @Test func verifiesSessionAndRefreshGrant() async throws {
        let accountID = UUID()
        let payload = Data("{\"access_token\":\"access\",\"refresh_token\":\"refresh\",\"expires_in\":3600,\"user\":{\"id\":\"\(accountID)\"}}".utf8)
        let transport = RecordingTransport(status: 200, payload: payload)
        let auth = SupabaseAccountAuthenticator(configuration: try configuration(), transport: transport)
        let session = try await auth.verifyEmailCode(email: "person@example.com", code: "123456")
        #expect(session.accountID == accountID)
        #expect(session.accessToken == "access")
        #expect(session.expiresAt > Date())
        _ = try await auth.refresh(session: session)
        let request = try #require(await transport.recorded())
        #expect(request.url?.query == "grant_type=refresh_token")
        #expect(request.url?.path == "/auth/v1/token")
    }

    @Test func refreshCannotSwitchAccounts() async throws {
        let payload = Data("{\"access_token\":\"access\",\"refresh_token\":\"refresh\",\"expires_in\":3600,\"user\":{\"id\":\"\(UUID())\"}}".utf8)
        let transport = RecordingTransport(status: 200, payload: payload)
        let auth = SupabaseAccountAuthenticator(configuration: try configuration(), transport: transport)
        let original = AccountSession(accountID: UUID(), accessToken: "old", refreshToken: "old-refresh",
                                      expiresAt: Date())
        await #expect(throws: AccountError.unauthorized) { try await auth.refresh(session: original) }
    }

    @Test func refusesAdminKeys() throws {
        let config = try configuration()
        #expect(throws: AccountError.invalidConfiguration) {
            try SupabaseConfiguration(supabaseURL: config.supabaseURL, publishableKey: "sb_secret_admin",
                                      callbackURL: config.callbackURL)
        }
    }

    @Test func backendErrorDoesNotExposeSecrets() async throws {
        let transport = RecordingTransport(status: 429, payload: Data("secret-token".utf8))
        let auth = SupabaseAccountAuthenticator(configuration: try configuration(), transport: transport)
        await #expect(throws: AccountError.rateLimited) {
            try await auth.requestEmailCode(email: "person@example.com")
        }
    }

    @Test func pkceIsRandomAndUsesSHA256() throws {
        let config = try configuration()
        let challenge = try GooglePKCEChallenge(configuration: config)
        let other = try GooglePKCEChallenge(configuration: config)
        #expect(challenge.verifier.count == 43)
        #expect(challenge.verifier != other.verifier)
        #expect(challenge.state != other.state)
        let items = try #require(URLComponents(url: challenge.authorizationURL,
                                              resolvingAgainstBaseURL: false)?.queryItems)
        let redirect = try #require(items.first(where: { $0.name == "redirect_to" })?.value)
        let callbackItems = try #require(URLComponents(string: redirect)?.queryItems)
        #expect(callbackItems.first(where: { $0.name == "state" })?.value == challenge.state)
        let digest = Data(SHA256.hash(data: Data(challenge.verifier.utf8))).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        #expect(items.first(where: { $0.name == "code_challenge" })?.value == digest)
        #expect(items.first(where: { $0.name == "code_challenge_method" })?.value == "s256")
        let callback = try #require(URL(string: "redent://auth/callback?state=\(challenge.state)&code=valid#ignored"))
        #expect(try challenge.code(from: callback, configuration: config) == "valid")
        #expect(throws: AccountError.invalidCode) {
            try challenge.code(from: #require(URL(string: "redent://auth/callback?state=wrong&code=valid")),
                               configuration: config)
        }
        #expect(throws: AccountError.invalidCode) {
            try challenge.code(from: #require(URL(string: "redent://auth/callback?code=valid")),
                               configuration: config)
        }
    }

    @Test func googleChallengeIsConsumedOnce() async throws {
        let auth = SupabaseAccountAuthenticator(configuration: try configuration())
        _ = try await auth.authorizationURL()
        await auth.cancelGoogleSignIn()
        await #expect(throws: AccountError.invalidCode) {
            try await auth.completeGoogleSignIn(callback: #require(URL(string: "redent://auth/callback?code=x")))
        }
    }

    private actor RecordingTransport: SupabaseHTTPTransport {
        let status: Int
        let payload: Data
        private var request: URLRequest?

        init(status: Int, payload: Data) { self.status = status; self.payload = payload }

        func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            self.request = request
            let url = try #require(request.url)
            return (payload, try #require(HTTPURLResponse(url: url,
                                                         statusCode: status, httpVersion: nil, headerFields: nil)))
        }

        func recorded() -> URLRequest? { request }
    }
}
