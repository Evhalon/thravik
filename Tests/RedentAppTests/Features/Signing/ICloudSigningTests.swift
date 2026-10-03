import Foundation
import Testing

@Suite("iCloud password signing")
struct ICloudSigningTests {
    @Test("A matching profile embeds the default Keychain group")
    func authorizedProfile() throws {
        let fixture = try ICloudSigningFixture()
        defer { fixture.remove() }
        try fixture.writeProfile()
        #expect(try fixture.sign() == 0)
        let signed = try fixture.signedEntitlements()
        #expect(signed["keychain-access-groups"] as? [String] == ["TESTTEAM1.app.redent.browser"])
        #expect(signed["com.apple.application-identifier"] as? String == "TESTTEAM1.app.redent.browser")
        #expect(signed["com.apple.developer.team-identifier"] as? String == "TESTTEAM1")
        #expect(signed["com.apple.security.network.client"] as? Bool == true)
        #expect(FileManager.default.fileExists(atPath: fixture.app.appendingPathComponent(
            "Contents/embedded.provisionprofile").path))
    }

    @Test("A custom access group is accepted only through a profile wildcard")
    func wildcardGroup() throws {
        let fixture = try ICloudSigningFixture()
        defer { fixture.remove() }
        try fixture.writeProfile(problem: "wildcard")
        #expect(try fixture.sign(["REDENT_ICLOUD_ACCESS_GROUP": "TESTTEAM1.shared.passwords"]) == 0)
        #expect(try fixture.signedEntitlements()["keychain-access-groups"] as? [String]
            == ["TESTTEAM1.shared.passwords"])
    }

    @Test("A required Keychain profile cannot be absent or mismatched", arguments: [
        "noGroups", "wrongApp", "wrongTeam", "expired"
    ])
    func invalidProfile(problem: String) throws {
        let fixture = try ICloudSigningFixture()
        defer { fixture.remove() }
        try fixture.writeProfile(problem: problem)
        #expect(try fixture.sign() != 0)
        #expect(!FileManager.default.fileExists(atPath: fixture.log.path))
        #expect(!FileManager.default.fileExists(atPath: fixture.app.appendingPathComponent(
            "Contents/embedded.provisionprofile").path))
    }

    @Test("A missing required profile fails before signing")
    func missingProfile() throws {
        let fixture = try ICloudSigningFixture()
        defer { fixture.remove() }
        #expect(try fixture.sign(["ICLOUD_PROVISIONING_PROFILE": ""]) != 0)
        #expect(!FileManager.default.fileExists(atPath: fixture.log.path))
    }

    @Test("A profile that does not authorize the signed leaf certificate fails closed")
    func certificateMismatch() throws {
        let fixture = try ICloudSigningFixture()
        defer { fixture.remove() }
        try fixture.writeProfile(problem: "wrongCertificate")
        #expect(try fixture.sign() != 0)
        #expect(!FileManager.default.fileExists(atPath: fixture.app.appendingPathComponent(
            "Contents/embedded.provisionprofile").path))
        let calls = try String(contentsOf: fixture.log, encoding: .utf8)
        #expect(!calls.contains("--sign - "))
        #expect(calls.contains("--display --extract-certificates"))
    }

    @Test("One profile can authorize passkeys and iCloud passwords together")
    func combinedCapabilities() throws {
        let fixture = try ICloudSigningFixture()
        defer { fixture.remove() }
        try fixture.writeProfile(passkeys: true)
        #expect(try fixture.sign([
            "PROVISIONING_PROFILE": fixture.profile.path, "REQUIRE_PASSKEYS": "1"
        ]) == 0)
        let signed = try fixture.signedEntitlements()
        #expect(signed["com.apple.developer.web-browser.public-key-credential"] as? Bool == true)
        #expect(signed["keychain-access-groups"] as? [String] == ["TESTTEAM1.app.redent.browser"])
    }
}
