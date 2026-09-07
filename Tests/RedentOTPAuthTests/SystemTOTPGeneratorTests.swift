import Testing
import Foundation
import RedentKit
@testable import RedentOTPAuth

@Suite struct SystemTOTPGeneratorTests {
    @Test func matchesRFC6238FirstVector() throws {
        let account = TOTPAccount(
            issuer: "Example", accountName: "alice",
            secret: Data("12345678901234567890".utf8),
            algorithm: .sha1, digits: 8, period: 30
        )
        let generator = SystemTOTPGenerator()
        let code = try generator.code(for: account, at: Date(timeIntervalSince1970: 59))
        #expect(code.digits == "94287082")
        #expect(code.period == 30)
    }
}
