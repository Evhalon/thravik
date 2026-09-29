import AuthenticationServices
import Testing
@testable import RedentVault

@Suite("System browser passkey authorization")
struct SystemPasskeyAuthorizationTests {
    @Test("macOS authorization states preserve granted and denied decisions")
    func stateMapping() {
        #expect(SystemPasskeyAuthorization.access(for: .authorized) == .authorized)
        #expect(SystemPasskeyAuthorization.access(for: .denied) == .denied)
        #expect(SystemPasskeyAuthorization.access(for: .notDetermined) == .notDetermined)
    }

    @Test("A SwiftPM executable without the managed entitlement never asks for passkeys")
    func unsignedBuildCannotRequestPasskeys() async {
        let authorizer = SystemPasskeyAuthorization()
        #expect(await authorizer.currentAccess() == .unavailable)
        #expect(await authorizer.requestAccess() == .unavailable)
    }
}
