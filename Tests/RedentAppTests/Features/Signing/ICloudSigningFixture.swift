import Foundation

struct ICloudSigningFixture {
    let directory: URL
    let app: URL
    let profile: URL
    let entitlements: URL
    let captured: URL
    let log: URL
    let certificate: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        app = directory.appendingPathComponent("Redent.app")
        profile = directory.appendingPathComponent("profile.provisionprofile")
        entitlements = directory.appendingPathComponent("base-entitlements.plist")
        captured = directory.appendingPathComponent("signed-entitlements.plist")
        log = directory.appendingPathComponent("codesign.log")
        certificate = directory.appendingPathComponent("leaf.der")
        try FileManager.default.createDirectory(at: app.appendingPathComponent("Contents/Helpers"),
                                                withIntermediateDirectories: true)
        try write("security", "#!/bin/sh\ncat \"$ICLOUD_TEST_PROFILE\"\n")
        try write("codesign", codesignStub)
        try Data("synthetic leaf certificate".utf8).write(to: certificate)
        let base: [String: Any] = ["com.apple.security.network.client": true]
        let data = try PropertyListSerialization.data(fromPropertyList: base, format: .xml, options: 0)
        try data.write(to: entitlements)
    }

    func writeProfile(problem: String = "none", passkeys: Bool = false) throws {
        var allowed: [String: Any] = [
            "com.apple.application-identifier": "TESTTEAM1.app.redent.browser",
            "com.apple.developer.team-identifier": "TESTTEAM1",
            "keychain-access-groups": [problem == "wildcard" ? "TESTTEAM1.*" : "TESTTEAM1.app.redent.browser"]
        ]
        if passkeys { allowed["com.apple.developer.web-browser.public-key-credential"] = true }
        if problem == "noGroups" { allowed.removeValue(forKey: "keychain-access-groups") }
        if problem == "wrongApp" { allowed["com.apple.application-identifier"] = "TESTTEAM1.other.app" }
        let value: [String: Any] = [
            "Entitlements": allowed,
            "DeveloperCertificates": [Data((problem == "wrongCertificate"
                ? "different leaf certificate" : "synthetic leaf certificate").utf8)],
            "Platform": ["OSX"],
            "TeamIdentifier": [problem == "wrongTeam" ? "OTHERTEAM" : "TESTTEAM1"],
            "ApplicationIdentifierPrefix": ["TESTTEAM1"],
            "ExpirationDate": Date(timeIntervalSinceNow: problem == "expired" ? -30 : 86_400)
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: value, format: .xml, options: 0)
        try data.write(to: profile)
    }

    func sign(_ overrides: [String: String] = [:]) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["scripts/sign-app.sh", app.path, "app.redent.browser", entitlements.path]
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        process.currentDirectoryURL = root
        var environment = ProcessInfo.processInfo.environment
        environment.merge([
            "PATH": directory.path + ":" + (environment["PATH"] ?? "/usr/bin:/bin"),
            "CODESIGN_IDENTITY": "Apple Development: Signing Tests",
            "PROVISIONING_PROFILE": "", "ICLOUD_PROVISIONING_PROFILE": profile.path,
            "REQUIRE_PASSKEYS": "0", "REQUIRE_ICLOUD_PASSWORDS": "1", "REQUIRE_SIGNING": "0",
            "ICLOUD_TEST_PROFILE": profile.path, "ICLOUD_TEST_CAPTURE": captured.path,
            "ICLOUD_TEST_LOG": log.path, "ICLOUD_TEST_LEAF": certificate.path
        ]) { _, next in next }
        environment.merge(overrides) { _, next in next }
        process.environment = environment
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    func signedEntitlements() throws -> [String: Any] {
        let value = try PropertyListSerialization.propertyList(from: Data(contentsOf: captured), format: nil)
        guard let entitlements = value as? [String: Any] else { throw FixtureError.invalidEntitlements }
        return entitlements
    }

    func remove() { try? FileManager.default.removeItem(at: directory) }

    private func write(_ name: String, _ contents: String) throws {
        let file = directory.appendingPathComponent(name)
        try contents.write(to: file, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: file.path)
    }

    private var codesignStub: String {
        """
        #!/bin/sh
        echo "$*" >> "$ICLOUD_TEST_LOG"
        if [ "$1" = "--display" ]; then
            shift; shift
            cp "$ICLOUD_TEST_LEAF" "$1"0
            exit 0
        fi
        while [ "$#" -gt 0 ]; do
            if [ "$1" = "--entitlements" ]; then cp "$2" "$ICLOUD_TEST_CAPTURE"; shift; fi
            shift
        done
        exit 0
        """
    }

    private enum FixtureError: Error { case invalidEntitlements }
}
