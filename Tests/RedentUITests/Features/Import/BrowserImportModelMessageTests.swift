import Foundation
import Testing
@testable import RedentUI

@MainActor
@Suite("Import failure copy")
struct BrowserImportModelMessageTests {
    @Test("A Keychain save failure is not blamed on a running browser")
    func saveFailure() {
        let text = BrowserImportModel.message(for: ["passwords-save"])
        #expect(text.contains("Keychain"))
        #expect(!text.contains("running"))
    }

    @Test("A missing encryption key asks for Allow, not a quit")
    func keyFailure() {
        let text = BrowserImportModel.message(for: ["passwords-key"])
        #expect(text.contains("Allow"))
        #expect(!text.contains("running"))
    }
}
