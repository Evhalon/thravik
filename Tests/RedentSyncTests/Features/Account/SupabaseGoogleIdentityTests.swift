import Foundation
import RedentKit
import Testing
@testable import RedentSync

struct SupabaseGoogleIdentityTests {
    @Test func googleExchangeKeepsCurrentMethodForLinkedEmailIdentity() async throws {
        let accountID = UUID()
        let payload = Data("{\"access_token\":\"access\",\"refresh_token\":\"refresh\",\"expires_in\":3600,\"user\":{\"id\":\"\(accountID)\",\"email\":\"actual@example.com\",\"app_metadata\":{\"provider\":\"email\",\"providers\":[\"email\",\"google\"]}}}".utf8)
        let config = try SupabaseConfiguration(supabaseURL: #require(URL(string: "https://example.supabase.co")),
                                               publishableKey: "sb_publishable_test",
                                               callbackURL: #require(URL(string: "redent://auth/callback")))
        let auth = SupabaseAccountAuthenticator(configuration: config,
                                                 transport: GoogleIdentityTransport(payload: payload))
        let authorization = try await auth.authorizationURL()
        let query = try #require(URLComponents(url: authorization, resolvingAgainstBaseURL: false)?.queryItems)
        let redirect = try #require(query.first(where: { $0.name == "redirect_to" })?.value)
        let callbackQuery = try #require(URLComponents(string: redirect)?.queryItems)
        let state = try #require(callbackQuery.first(where: { $0.name == "state" })?.value)
        let callback = try #require(URL(string: "redent://auth/callback?state=\(state)&code=valid"))
        let session = try await auth.completeGoogleSignIn(callback: callback)
        #expect(session.accountID == accountID)
        #expect(session.email == "actual@example.com")
        #expect(session.loginMethod == .google)
    }
}

private actor GoogleIdentityTransport: SupabaseHTTPTransport {
    private let payload: Data
    init(payload: Data) { self.payload = payload }
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: 200,
                                             httpVersion: nil, headerFields: nil) else {
            throw AccountError.invalidResponse
        }
        return (payload, response)
    }
}
