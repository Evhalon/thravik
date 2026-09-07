import Foundation
import Testing
@testable import RedentImport

@Suite("ChromeEpoch")
struct ChromeEpochTests {
    @Test("zero microseconds means never")
    func zeroIsDistantPast() {
        #expect(ChromeEpoch.date(fromMicroseconds: 0) == .distantPast)
    }

    @Test("a known Chrome timestamp converts to the right Unix time")
    func pinnedValueConverts() {
        // 13349788200000000 microseconds since 1601-01-01 == 2024-01-15T10:30:00Z.
        let date = ChromeEpoch.date(fromMicroseconds: 13_349_788_200_000_000)
        let expected = Date(timeIntervalSince1970: 1_705_314_600)
        #expect(abs(date.timeIntervalSince(expected)) < 1)
    }

    @Test("round trip through both directions")
    func roundTrips() {
        let original = Date(timeIntervalSince1970: 1_700_000_000)
        let microseconds = ChromeEpoch.microseconds(from: original)
        let restored = ChromeEpoch.date(fromMicroseconds: microseconds)
        #expect(abs(restored.timeIntervalSince(original)) < 1)
    }
}
