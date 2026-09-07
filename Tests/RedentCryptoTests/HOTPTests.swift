import Testing
import Foundation
@testable import RedentCrypto

/// RFC 4226 Appendix D test vectors.
@Suite struct HOTPTests {
    private static let secret = Data("12345678901234567890".utf8)

    private static let expected: [UInt64: String] = [
        0: "755224", 1: "287082", 2: "359152", 3: "969429", 4: "338314",
        5: "254676", 6: "287922", 7: "162583", 8: "399871", 9: "520489",
    ]

    @Test(arguments: Array(0...9))
    func rfc4226Vectors(counter: Int) {
        let code = HOTP.generate(
            secret: Self.secret, counter: UInt64(counter), digits: 6, algorithm: .sha1
        )
        #expect(code == Self.expected[UInt64(counter)])
    }

    @Test func padsWithLeadingZeros() {
        // Counter 0 with SHA1 produces a truncated value with a small enough
        // remainder that padding matters for some secrets; verify length always holds.
        let code = HOTP.generate(secret: Self.secret, counter: 0, digits: 8, algorithm: .sha1)
        #expect(code.count == 8)
    }
}
