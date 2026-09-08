import Testing
@testable import RedentKit

@Suite("App version")
struct AppVersionTests {
    @Test("A dotted tag parses, with or without GitHub's v")
    func parses() throws {
        #expect(AppVersion("0.1.2")?.description == "0.1.2")
        #expect(AppVersion("v0.1.2")?.description == "0.1.2")
        #expect(AppVersion(" 1.0 ")?.description == "1.0")
    }

    @Test("Fields compare as numbers, not as text")
    func ordersNumerically() throws {
        let older = try #require(AppVersion("0.1.9"))
        let newer = try #require(AppVersion("0.1.10"))
        #expect(older < newer)
        #expect(!(newer < older))
    }

    @Test("Missing trailing fields are zero")
    func padsShortVersions() throws {
        #expect(AppVersion("1.2") == AppVersion("1.2.0"))
        let short = try #require(AppVersion("1.2"))
        let long = try #require(AppVersion("1.2.1"))
        #expect(short < long)
    }

    @Test("A tag that is not a dotted number is rejected", arguments: [
        "", "beta", "1.2.3-rc1", "1..2", "1.-2", "v", "2026-09-08"
    ])
    func rejectsUncomparableTags(_ raw: String) {
        #expect(AppVersion(raw) == nil)
    }
}
