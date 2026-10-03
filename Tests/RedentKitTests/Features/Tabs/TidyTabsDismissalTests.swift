import Foundation
import Testing
@testable import RedentKit

@Suite("Tidy tabs dismissal")
struct TidyTabsDismissalTests {
    @Test("Empty candidates never show")
    func empty() {
        let dismissal = TidyTabsDismissal()
        #expect(!dismissal.shouldShowSuggestion(for: []))
    }

    @Test("Dismiss hides the same set until it grows")
    func suppressUntilGrowth() {
        var dismissal = TidyTabsDismissal()
        let first: Set = [UUID(), UUID(), UUID(), UUID(), UUID()]
        #expect(dismissal.shouldShowSuggestion(for: first))
        dismissal.dismiss(candidates: first)
        #expect(!dismissal.shouldShowSuggestion(for: first))
        var grown = first
        grown.insert(UUID())
        #expect(dismissal.shouldShowSuggestion(for: grown))
    }

    @Test("Earlier archived batches stay quiet after a later one")
    func suppressionAccumulates() {
        var dismissal = TidyTabsDismissal()
        let restored: Set = [UUID(), UUID(), UUID(), UUID(), UUID()]
        let later: Set = [UUID(), UUID(), UUID(), UUID(), UUID()]
        dismissal.dismiss(candidates: restored)
        dismissal.dismiss(candidates: later)
        #expect(!dismissal.shouldShowSuggestion(for: restored))
        #expect(!dismissal.shouldShowSuggestion(for: restored.union(later)))
    }
}
