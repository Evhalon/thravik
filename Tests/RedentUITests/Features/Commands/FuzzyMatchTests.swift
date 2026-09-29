import Testing
@testable import RedentUI

@Suite("Fuzzy matching")
struct FuzzyMatchTests {
    @Test("A fragment finds a brand at the end of a long title")
    func brandInTitle() {
        #expect(FuzzyMatch.score("git", in: "Pull request #182 — OnePanel — GitHub") == 3)
    }

    @Test("Scores fall from exact to prefix to word to substring to letters in order")
    func ladder() {
        #expect(FuzzyMatch.score("github", in: "GitHub") == 5)
        #expect(FuzzyMatch.score("git", in: "GitHub") == 4)
        #expect(FuzzyMatch.score("hub", in: "GitHub") == 2)
        #expect(FuzzyMatch.score("gthb", in: "GitHub") == 1)
        #expect(FuzzyMatch.score("xyz", in: "GitHub") == 0)
    }

    @Test("Two letters in order are not a match — they match nearly everything")
    func shortSubsequence() {
        #expect(FuzzyMatch.score("gb", in: "GitHub") == 0)
    }

    @Test("Every word must land somewhere; URLs only match literally")
    func multiWord() {
        #expect(FuzzyMatch.matches("pull github", fields: ["Pull request — GitHub"]))
        #expect(!FuzzyMatch.matches("pull gitlab", fields: ["Pull request — GitHub"]))
        #expect(FuzzyMatch.matches("onepanel", fields: [], exact: ["https://github.com/acme/onepanel"]))
        #expect(!FuzzyMatch.matches("gtb", fields: [], exact: ["https://github.com"]))
    }
}
