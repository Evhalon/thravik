import CommonCrypto
import Foundation
import RedentKit
import Testing
@testable import RedentImport

@Suite("Reading both Chromium login databases")
struct ChromiumPasswordReaderTests {
    @Test("Local and account-synced logins are merged")
    func mergesBothFiles() throws {
        let profile = FileManager.default.temporaryDirectory
            .appending(path: "redent-login-profile-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: profile, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: profile) }

        let key = ChromiumCrypto.deriveKey(fromSecret: Data("peanuts".utf8))
        try writeLogins(named: "Login Data", in: profile, key: key, host: "github.com", user: "local")
        try writeLogins(named: "Login Data For Account", in: profile, key: key, host: "gitlab.com", user: "sync")

        let credentials = try ChromiumPasswordReader.read(from: profile, key: key)
        let hosts = Set(credentials.map(\.origin.host))
        #expect(hosts == ["github.com", "gitlab.com"])
    }

    @Test("A missing account-sync database is not an error")
    func localOnly() throws {
        let profile = FileManager.default.temporaryDirectory
            .appending(path: "redent-login-profile-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: profile, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: profile) }

        let key = ChromiumCrypto.deriveKey(fromSecret: Data("peanuts".utf8))
        try writeLogins(named: "Login Data", in: profile, key: key, host: "example.com", user: "me")

        let credentials = try ChromiumPasswordReader.read(from: profile, key: key)
        #expect(credentials.map(\.username) == ["me"])
    }
}

private func writeLogins(named fileName: String, in profile: URL, key: [UInt8], host: String, user: String) throws {
    let url = profile.appending(path: fileName)
    let blob = try encrypt("secret", key: key)
    let hex = blob.map { String(format: "%02x", $0) }.joined()
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
    process.arguments = [
        url.path,
        """
        CREATE TABLE logins (
          origin_url TEXT, signon_realm TEXT, username_value TEXT,
          password_value BLOB, blacklisted_by_user INTEGER DEFAULT 0
        );
        INSERT INTO logins VALUES (
          'https://\(host)/login', 'https://\(host)/', '\(user)', X'\(hex)', 0
        );
        """
    ]
    try process.run()
    process.waitUntilExit()
    #expect(process.terminationStatus == 0)
}

private func encrypt(_ plaintext: String, key: [UInt8]) throws -> Data {
    let bytes = Array(plaintext.utf8)
    var ciphertext = [UInt8](repeating: 0, count: bytes.count + kCCBlockSizeAES128)
    var count = 0
    let iv = [UInt8](repeating: 0x20, count: kCCBlockSizeAES128)
    let status = CCCrypt(
        CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmAES128),
        CCOptions(kCCOptionPKCS7Padding), key, key.count, iv,
        bytes, bytes.count, &ciphertext, ciphertext.count, &count
    )
    guard status == kCCSuccess else { throw ImportError.decryptionKeyUnavailable }
    return Data("v10".utf8) + Data(ciphertext.prefix(count))
}
