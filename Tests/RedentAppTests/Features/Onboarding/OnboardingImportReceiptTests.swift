import Foundation
import RedentKit
@testable import Redent
import Testing

@MainActor
struct OnboardingImportReceiptTests {
    @Test func receiptRestoresAndDemoDoesNotOverwriteIt() throws {
        let suite = "OnboardingImportReceipt.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let onboarding = AppOnboarding(defaults: defaults)
        let receipt = BrowserImportReceipt(
            summary: ImportSummary(history: 2, bookmarks: 3, passwords: 1),
            profileNames: ["Chrome — Personal", "Chrome — Work"],
            problem: "Some passwords were skipped."
        )

        onboarding.recordImport(receipt)
        onboarding.restartReal()
        #expect(onboarding.model.importReceipt == receipt)
        #expect(AppOnboarding(defaults: defaults).model.importReceipt == receipt)

        onboarding.model.finish()
        onboarding.model.startDemo()
        #expect(onboarding.model.isDemo)
        onboarding.recordImport(BrowserImportReceipt(
            summary: ImportSummary(history: 99), profileNames: ["Demo"], problem: nil
        ))

        #expect(onboarding.model.importReceipt == receipt)
        #expect(AppOnboarding(defaults: defaults).model.importReceipt == receipt)
    }
}
