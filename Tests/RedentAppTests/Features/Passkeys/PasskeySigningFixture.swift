import Foundation

struct PasskeySigningFixture {
    static let entitlement = "com.apple.developer.web-browser.public-key-credential"
    let directory: URL
    let app: URL
    let profile: URL
    var embeddedProfile: URL { app.appendingPathComponent("Contents/embedded.provisionprofile") }
    var capturedEntitlements: URL { directory.appendingPathComponent("signed.plist") }
    var log: URL { directory.appendingPathComponent("codesign.log") }

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        app = directory.appendingPathComponent("Thravik.app")
        profile = directory.appendingPathComponent("browser.provisionprofile")
        try FileManager.default.createDirectory(
            at: app.appendingPathComponent("Contents/Helpers"), withIntermediateDirectories: true
        )
        try writeTool("security", script: "#!/bin/sh\ncat \"$PASSKEY_TEST_PROFILE\"\n")
        try writeTool("codesign", script: """
        #!/bin/sh
        echo "$*" >> "$PASSKEY_TEST_LOG"
        [ "${SIGNING_FAIL:-0}" = "1" ] && exit 1
        [ "$1" = "--verify" ] && exit "${VERIFY_FAIL:-0}"
        while [ "$#" -gt 0 ]; do
            if [ "$1" = "--entitlements" ]; then
                cp "$2" "$PASSKEY_TEST_ENTITLEMENTS"
                shift
            fi
            shift
        done
        exit 0
        """)
    }

    func writeProfile(problem: String = "none") throws {
        var entitlements: [String: Any] = [
            Self.entitlement: true,
            "com.apple.application-identifier": "TESTTEAM1.app.redent.browser",
            "com.apple.developer.team-identifier": "TESTTEAM1"
        ]
        if problem == "missingApproval" { entitlements[Self.entitlement] = false }
        if problem == "wrongApp" { entitlements["com.apple.application-identifier"] = "TESTTEAM1.other.app" }
        if problem == "wildcard" { entitlements["com.apple.application-identifier"] = "TESTTEAM1.*" }
        let profile: [String: Any] = [
            "Entitlements": entitlements,
            "Platform": problem == "iOS" ? ["iOS"] : ["OSX"],
            "TeamIdentifier": problem == "wrongTeam" ? ["OTHERTEAM"] : ["TESTTEAM1"],
            "ApplicationIdentifierPrefix": ["TESTTEAM1"],
            "ExpirationDate": Date(timeIntervalSinceNow: problem == "expired" ? -60 : 86_400)
        ]
        try PropertyListSerialization.data(fromPropertyList: profile, format: .xml, options: 0).write(to: self.profile)
    }

    func sign(overrides: [String: String] = [:]) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["scripts/sign-app.sh", app.path, "app.redent.browser", "Resources/Redent.entitlements"]
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        process.currentDirectoryURL = root
        var environment = ProcessInfo.processInfo.environment
        environment.merge([
            "PATH": directory.path + ":" + (environment["PATH"] ?? "/usr/bin:/bin"),
            "CODESIGN_IDENTITY": "Apple Development: Passkey Tests",
            "PROVISIONING_PROFILE": profile.path, "REQUIRE_PASSKEYS": "1", "REQUIRE_SIGNING": "0",
            "PASSKEY_TEST_PROFILE": profile.path, "PASSKEY_TEST_LOG": log.path,
            "PASSKEY_TEST_ENTITLEMENTS": capturedEntitlements.path,
            "SIGNING_FAIL": "0", "VERIFY_FAIL": "0"
        ]) { _, new in new }
        environment.merge(overrides) { _, new in new }
        process.environment = environment
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    func remove() { try? FileManager.default.removeItem(at: directory) }

    private func writeTool(_ name: String, script: String) throws {
        let path = directory.appendingPathComponent(name)
        try script.write(to: path, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path.path)
    }
}
