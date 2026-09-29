import Foundation
import Testing

@Suite("Browser passkey signing")
struct PasskeySigningTests {
    @Test("An approved profile is embedded and its managed identity accompanies the passkey entitlement")
    func approvedProfile() throws {
        let fixture = try PasskeySigningFixture()
        defer { fixture.remove() }
        try fixture.writeProfile()
        #expect(try fixture.sign() == 0)
        #expect(try Data(contentsOf: fixture.embeddedProfile) == Data(contentsOf: fixture.profile))
        let signed = try #require(PropertyListSerialization.propertyList(
            from: Data(contentsOf: fixture.capturedEntitlements), format: nil
        ) as? [String: Any])
        #expect(signed[PasskeySigningFixture.entitlement] as? Bool == true)
        #expect(signed["com.apple.application-identifier"] as? String == "TESTTEAM1.app.redent.browser")
        #expect(signed["com.apple.developer.team-identifier"] as? String == "TESTTEAM1")
        #expect(signed["com.apple.security.network.client"] as? Bool == true)
        #expect(try String(contentsOf: fixture.log, encoding: .utf8).contains("--verify --strict"))
    }

    @Test("A restricted profile must authorize this app on macOS", arguments: [
        "missingApproval", "wrongApp", "wildcard", "wrongTeam", "expired", "iOS"
    ])
    func invalidProfile(problem: String) throws {
        let fixture = try PasskeySigningFixture()
        defer { fixture.remove() }
        try fixture.writeProfile(problem: problem)
        #expect(try fixture.sign() != 0)
        #expect(!FileManager.default.fileExists(atPath: fixture.log.path))
        #expect(!FileManager.default.fileExists(atPath: fixture.embeddedProfile.path))
    }

    @Test("Passkeys cannot silently fall back to an ad-hoc signature", arguments: ["SIGNING_FAIL", "VERIFY_FAIL"])
    func managedSigningFailure(failure: String) throws {
        let fixture = try PasskeySigningFixture()
        defer { fixture.remove() }
        try fixture.writeProfile()
        #expect(try fixture.sign(overrides: [failure: "1"]) != 0)
        #expect(!FileManager.default.fileExists(atPath: fixture.embeddedProfile.path))
        let calls = try String(contentsOf: fixture.log, encoding: .utf8)
        #expect(!calls.contains("--sign - "))
    }

    @Test("A local build removes a release profile and keeps its ordinary entitlements")
    func localBuild() throws {
        let fixture = try PasskeySigningFixture()
        defer { fixture.remove() }
        try Data("stale profile".utf8).write(to: fixture.embeddedProfile)
        #expect(try fixture.sign(overrides: [
            "PROVISIONING_PROFILE": "", "REQUIRE_PASSKEYS": "0", "CODESIGN_IDENTITY": "-"
        ]) == 0)
        #expect(!FileManager.default.fileExists(atPath: fixture.embeddedProfile.path))
        let signed = try #require(PropertyListSerialization.propertyList(
            from: Data(contentsOf: fixture.capturedEntitlements), format: nil
        ) as? [String: Any])
        #expect(signed[PasskeySigningFixture.entitlement] == nil)
        #expect(signed["com.apple.security.network.client"] as? Bool == true)
    }

    @Test("An explicitly required passkey build fails without a profile or signing identity")
    func missingSigningInputs() throws {
        let fixture = try PasskeySigningFixture()
        defer { fixture.remove() }
        #expect(try fixture.sign(overrides: ["PROVISIONING_PROFILE": ""]) != 0)
        try fixture.writeProfile()
        #expect(try fixture.sign(overrides: ["CODESIGN_IDENTITY": "-"]) != 0)
        #expect(!FileManager.default.fileExists(atPath: fixture.log.path))
    }
}
