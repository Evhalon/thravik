import Foundation
import Security
import Testing
@testable import RedentVault

@Suite("Keychain attribute decoding")
struct KeychainAttributeCodecTests {
    @Test("A single match is treated as a one-element list")
    func singleDictionary() throws {
        let dict: [String: Any] = [kSecAttrAccount as String: "one"]
        let rows = try KeychainAttributeCodec.dictionaries(from: dict)
        #expect(rows.count == 1)
        #expect(rows[0][kSecAttrAccount as String] as? String == "one")
    }

    @Test("Several matches stay an array")
    func arrayOfDictionaries() throws {
        let rows = try KeychainAttributeCodec.dictionaries(from: [
            [kSecAttrAccount as String: "a"],
            [kSecAttrAccount as String: "b"]
        ])
        #expect(rows.count == 2)
    }

    @Test("Printable JSON generic attributes still decode")
    func genericAsString() throws {
        let json = #"{"scheme":"https","host":"example.com","username":"me","createdAt":0,"useCount":0}"#
        let data = KeychainAttributeCodec.genericData(from: [kSecAttrGeneric as String: json])
        let metadata = try JSONDecoder().decode(CredentialMetadata.self, from: try #require(data))
        #expect(metadata.host == "example.com")
        #expect(metadata.username == "me")
    }

    @Test("Binary generic attributes still decode")
    func genericAsData() throws {
        let payload = Data(#"{"scheme":"https","host":"a.com","username":"x","createdAt":1,"useCount":2}"#.utf8)
        let data = KeychainAttributeCodec.genericData(from: [kSecAttrGeneric as String: payload])
        #expect(data == payload)
    }

    @Test("A heterogeneous array of dictionaries still decodes")
    func anyArrayOfDictionaries() throws {
        let rows: [Any] = [
            [kSecAttrAccount as String: "a"],
            [kSecAttrAccount as String: "b"]
        ]
        let decoded = try KeychainAttributeCodec.dictionaries(from: rows)
        #expect(decoded.count == 2)
    }

    @Test("Account attributes stored as Data still decode")
    func accountAsData() {
        let uuid = "F3AA5AE4-7E75-4808-B4D7-42B6AED774D7"
        let account = KeychainAttributeCodec.account(from: [kSecAttrAccount as String: Data(uuid.utf8)])
        #expect(account == uuid)
    }
}
