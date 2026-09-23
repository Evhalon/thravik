import Foundation
import Testing
@testable import RedentUI

@Suite("Inline address completion")
struct InlineCompletionFinderTests {
    private func url(_ text: String) throws -> URL { try #require(URL(string: text)) }

    @Test("A bare word completes to the site, keeping what was typed")
    func completesHost() throws {
        let found = InlineCompletionFinder.completion(for: "GiT", candidates: [try url("https://www.github.com/apple/swift")])
        #expect(found?.text == "GiThub.com")
        #expect(found?.suffix == "hub.com")
        #expect(found?.url == (try url("https://www.github.com")))
    }

    @Test("A slash asks for a path, and the completion follows")
    func completesPath() throws {
        let found = InlineCompletionFinder.completion(for: "github.com/ap", candidates: [try url("https://github.com/apple/")])
        #expect(found?.text == "github.com/apple")
    }

    @Test("An http site keeps its scheme and port")
    func keepsSchemeAndPort() throws {
        let found = InlineCompletionFinder.completion(for: "local", candidates: [try url("http://localhost:3000/app")])
        #expect(found?.text == "localhost:3000")
        #expect(found?.url == (try url("http://localhost:3000")))
    }

    @Test("Phrases, full URLs and exact matches are left alone", arguments: ["how to", "https://git", "github.com"])
    func leavesAlone(_ typed: String) throws {
        #expect(InlineCompletionFinder.completion(for: typed, candidates: [try url("https://github.com")]) == nil)
    }

    @Test("The best-ranked candidate that fits wins")
    func firstFittingCandidateWins() throws {
        let found = InlineCompletionFinder.completion(
            for: "g", candidates: [try url("https://apple.com"), try url("https://gmail.com"), try url("https://github.com")]
        )
        #expect(found?.text == "gmail.com")
    }
}
