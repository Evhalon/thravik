import Foundation
import RedentKit
import Testing

struct AccountSessionIdentityTests {
    @Test func identitySurvivesEncoding() throws {
        let session = AccountSession(accountID: UUID(), accessToken: "access", refreshToken: "refresh",
                                     expiresAt: .distantFuture,
                                     identity: AccountIdentity(email: "real@example.com", loginMethod: .google))
        let decoded = try JSONDecoder().decode(AccountSession.self, from: JSONEncoder().encode(session))
        #expect(decoded.email == "real@example.com")
        #expect(decoded.loginMethod == .google)
        #expect(decoded.description == "AccountSession(redacted)")
    }

    @Test func legacySessionDecodesWithExplicitUnknownMethod() throws {
        let session = AccountSession(accountID: UUID(), accessToken: "access", refreshToken: "refresh",
                                     expiresAt: .distantFuture)
        var fields = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(session)) as? [String: Any])
        fields.removeValue(forKey: "identity")
        let legacy = try JSONDecoder().decode(AccountSession.self, from: JSONSerialization.data(withJSONObject: fields))
        #expect(legacy.email == nil)
        #expect(legacy.loginMethod == .unknown)
    }
}
