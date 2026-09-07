import Testing
import Foundation
@testable import RedentCrypto

/// RFC 6238 Appendix B test vectors, 8 digits, 30s period.
@Suite struct TOTPTests {
    private static let sha1Secret = Data("12345678901234567890".utf8)
    private static let sha256Secret = Data("12345678901234567890123456789012".utf8)
    private static let sha512Secret = Data(
        "1234567890123456789012345678901234567890123456789012345678901234".utf8
    )

    struct Vector {
        let time: TimeInterval
        let sha1: String
        let sha256: String
        let sha512: String
    }

    private static let vectors: [Vector] = [
        Vector(time: 59, sha1: "94287082", sha256: "46119246", sha512: "90693936"),
        Vector(time: 1_111_111_109, sha1: "07081804", sha256: "68084774", sha512: "25091201"),
        Vector(time: 1_111_111_111, sha1: "14050471", sha256: "67062674", sha512: "99943326"),
        Vector(time: 1_234_567_890, sha1: "89005924", sha256: "91819424", sha512: "93441116"),
        Vector(time: 2_000_000_000, sha1: "69279037", sha256: "90698825", sha512: "38618901"),
        Vector(time: 20_000_000_000, sha1: "65353130", sha256: "77737706", sha512: "47863826"),
    ]

    @Test(arguments: vectors)
    func sha1Vectors(vector: Vector) {
        let result = TOTP.generate(
            secret: Self.sha1Secret, at: Date(timeIntervalSince1970: vector.time),
            period: 30, digits: 8, algorithm: .sha1
        )
        #expect(result.digits == vector.sha1)
        #expect(result.period == 30)
    }

    @Test(arguments: vectors)
    func sha256Vectors(vector: Vector) {
        let result = TOTP.generate(
            secret: Self.sha256Secret, at: Date(timeIntervalSince1970: vector.time),
            period: 30, digits: 8, algorithm: .sha256
        )
        #expect(result.digits == vector.sha256)
    }

    @Test(arguments: vectors)
    func sha512Vectors(vector: Vector) {
        let result = TOTP.generate(
            secret: Self.sha512Secret, at: Date(timeIntervalSince1970: vector.time),
            period: 30, digits: 8, algorithm: .sha512
        )
        #expect(result.digits == vector.sha512)
    }

    @Test func windowStartAlignsToPeriodBoundary() {
        let result = TOTP.generate(
            secret: Self.sha1Secret, at: Date(timeIntervalSince1970: 59),
            period: 30, digits: 8, algorithm: .sha1
        )
        #expect(result.windowStart == Date(timeIntervalSince1970: 30))
    }
}

extension TOTPTests.Vector: CustomTestStringConvertible {
    var testDescription: String { "t=\(Int(time))" }
}
