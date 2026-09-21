import Foundation
import RedentKit
import Testing

struct ExternalLinkDebouncerTests {
    private let link = URL(string: "https://example.com/a")
    private let start = Date(timeIntervalSinceReferenceDate: 0)

    @Test("The same link handed over twice in a row opens once")
    func duplicateIsDropped() throws {
        let url = try #require(link)
        var debouncer = ExternalLinkDebouncer()
        let first = debouncer.admits(url, at: start)
        let echo = debouncer.admits(url, at: start.addingTimeInterval(0.05))
        #expect(first)
        #expect(!echo)
    }

    @Test("The same link clicked again later opens again")
    func laterRepeatOpens() throws {
        let url = try #require(link)
        var debouncer = ExternalLinkDebouncer()
        let first = debouncer.admits(url, at: start)
        let again = debouncer.admits(url, at: start.addingTimeInterval(3))
        #expect(first)
        #expect(again)
    }

    @Test("A different link is never held back")
    func differentLinkOpens() throws {
        let url = try #require(link)
        let other = try #require(URL(string: "https://example.com/b"))
        var debouncer = ExternalLinkDebouncer()
        let first = debouncer.admits(url, at: start)
        let second = debouncer.admits(other, at: start.addingTimeInterval(0.05))
        #expect(first)
        #expect(second)
    }
}
