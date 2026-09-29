import Foundation
import RedentKit
import Testing
@testable import RedentVault

@Suite("Credential Keychain payload")
struct KeychainCredentialCodecTests {
    private func sample() -> Credential {
        Credential(
            origin: Origin(scheme: "https", host: "accounts.google.com"),
            username: "very.long.email.address@gmail.com",
            password: "hunter2"
        )
    }

    @Test("A login survives without kSecAttrGeneric")
    func roundtripWithoutGeneric() throws {
        let credential = sample()
        let data = try KeychainCredentialCodec.encode(credential)
        #expect(data.count > 64)
        let item = KeychainStore.Item(
            account: credential.id.uuidString, valueData: data, genericData: nil
        )
        let decoded = try #require(KeychainCredentialCodec.decode(item))
        #expect(decoded.username == credential.username)
        #expect(decoded.password == credential.password)
        #expect(decoded.origin.host == credential.origin.host)
    }

    @Test("Truncated generic does not hide a payload")
    func truncatedGenericIgnored() throws {
        let credential = sample()
        let item = KeychainStore.Item(
            account: credential.id.uuidString,
            valueData: try KeychainCredentialCodec.encode(credential),
            genericData: Data("{".utf8)
        )
        let decoded = try #require(KeychainCredentialCodec.decode(item))
        #expect(decoded.username == credential.username)
    }

    @Test("Legacy generic + plaintext password still decodes")
    func legacyGeneric() throws {
        let credential = sample()
        let generic = try JSONEncoder().encode(CredentialMetadata(credential: credential))
        let item = KeychainStore.Item(
            account: credential.id.uuidString,
            valueData: Data(credential.password.utf8),
            genericData: generic
        )
        let decoded = try #require(KeychainCredentialCodec.decode(item))
        #expect(decoded.password == "hunter2")
        #expect(decoded.origin.host == "accounts.google.com")
    }
}
