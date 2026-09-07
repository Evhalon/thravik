import Foundation
import Testing
@testable import RedentKit

@Suite("Domain model behaviour")
struct ModelTests {
    @Test("Ads and trackers are blocked unless the user turns the shield off")
    func blockingDefaultsOn() {
        #expect(BrowserSettings().blocksTrackers)
    }

    @Test("Sidebar width is clamped to the allowed range")
    func sidebarClamping() {
        #expect(BrowserSettings(sidebarWidth: 10).sidebarWidth == BrowserSettings.sidebarWidthRange.lowerBound)
        #expect(BrowserSettings(sidebarWidth: 9_000).sidebarWidth == BrowserSettings.sidebarWidthRange.upperBound)
        #expect(BrowserSettings(sidebarWidth: 240).sidebarWidth == 240)
    }

    @Test("Nonsense TOTP parameters are corrected, not trusted")
    func totpParameterGuards() {
        let account = TOTPAccount(issuer: "X", accountName: "y", secret: Data(), digits: 2, period: 0)
        #expect(account.digits == 6)
        #expect(account.period == 30)
    }

    @Test("Codes report their remaining window")
    func codeCountdown() {
        let start = Date(timeIntervalSince1970: 1_700_000_010)
        let code = TOTPCode(digits: "123456", validFrom: start, period: 30)
        #expect(code.secondsRemaining(at: start) == 30)
        #expect(code.secondsRemaining(at: start.addingTimeInterval(29)) == 1)
        #expect(code.secondsRemaining(at: start.addingTimeInterval(60)) == 0)
        #expect(code.fractionRemaining(at: start.addingTimeInterval(15)) == 0.5)
    }

    @Test("Codes are grouped for reading aloud")
    func grouping() {
        #expect(TOTPCode(digits: "123456", validFrom: .now, period: 30).grouped == "123 456")
        #expect(TOTPCode(digits: "12345678", validFrom: .now, period: 30).grouped == "1234 5678")
    }

    @Test("A tab falls back to its host, then to a placeholder")
    func tabTitles() {
        let untitled = TabSnapshot(url: URL(string: "https://www.example.com/x"))
        #expect(untitled.displayTitle == "example.com")
        #expect(TabSnapshot().displayTitle == "New Tab")
        #expect(TabSnapshot(url: nil, title: "Hello").displayTitle == "Hello")
    }

    @Test("Hibernation thresholds match the policy")
    func hibernationPolicy() {
        #expect(HibernationPolicy.off.idleThreshold == nil)
        #expect(HibernationPolicy.balanced.idleThreshold == 900)
        #expect(HibernationPolicy.aggressive.idleThreshold == 180)
    }
}
