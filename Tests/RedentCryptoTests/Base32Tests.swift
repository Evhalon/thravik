import Testing
import Foundation
@testable import RedentCrypto

@Suite struct Base32Tests {
    @Test(arguments: [
        ("", ""),
        ("f", "MY======"),
        ("fo", "MZXQ===="),
        ("foo", "MZXW6==="),
        ("foob", "MZXW6YQ="),
        ("fooba", "MZXW6YTB"),
        ("foobar", "MZXW6YTBOI======"),
    ])
    func rfc4648Vectors(plain: String, encoded: String) throws {
        let data = Data(plain.utf8)
        #expect(Base32.encode(data, padded: true) == encoded)
        #expect(try Base32.decode(encoded) == data)
    }

    @Test func encodeUnpaddedByDefault() {
        #expect(Base32.encode(Data("foob".utf8)) == "MZXW6YQ")
    }

    @Test func decodeIsCaseInsensitive() throws {
        #expect(try Base32.decode("mzxw6ytb") == Data("fooba".utf8))
    }

    @Test func decodeToleratesMissingPadding() throws {
        #expect(try Base32.decode("MZXW6YQ") == Data("foob".utf8))
    }

    @Test func decodeIgnoresSpacesAndDashes() throws {
        #expect(try Base32.decode("MZXW-6YTB ") == Data("fooba".utf8))
    }

    @Test func decodeRejectsInvalidCharacter() {
        #expect(throws: Base32Error.invalidCharacter("1")) {
            try Base32.decode("MZXW1YTB")
        }
    }

    @Test func decodeRejectsFractionalByteLength() {
        #expect(throws: Base32Error.invalidLength) {
            try Base32.decode("A")
        }
    }
}
