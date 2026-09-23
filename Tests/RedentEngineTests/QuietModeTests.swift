import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

/// Quiet mode against a real web view: the banner and autoplay rules live in an
/// injected script, so only a page shows whether they press the right button.
@Suite("Quiet mode")
@MainActor
struct QuietModeTests {
    @Test("A consent platform's banner is declined, and its accept button left alone")
    func declinesKnownPlatform() async throws {
        let tab = try await QuietPage.load("""
        <div id='onetrust-banner-sdk'>
          <button id='onetrust-accept-btn-handler' onclick='window.accepted = true'>Accept All</button>
          <button id='onetrust-reject-all-handler' onclick='window.rejected = true'>Reject All</button>
        </div>
        """)
        #expect(try await QuietPage.settles(tab, "window.rejected === true"))
        #expect(try await QuietPage.value(tab, "window.accepted === undefined") as? Bool == true)
        #expect(tab.quietReceipt.declinedCookieBanners == 1)
    }

    @Test("A home-grown banner is declined by its reject label, in Italian too")
    func declinesByLabel() async throws {
        let tab = try await QuietPage.load("""
        <div class='cookie-notice'>
          <button onclick='window.accepted = true'>Accetta tutto</button>
          <button onclick='window.rejected = true'>Rifiuta tutto</button>
        </div>
        """)
        #expect(try await QuietPage.settles(tab, "window.rejected === true"))
        #expect(try await QuietPage.value(tab, "window.accepted === undefined") as? Bool == true)
    }

    @Test("A banner that shows up late is still declined")
    func declinesLateBanner() async throws {
        let tab = try await QuietPage.load("""
        <script>
        setTimeout(function () {
          document.body.insertAdjacentHTML('beforeend',
            "<div id='consent'><button onclick='window.rejected = true'>Reject all</button></div>");
        }, 400);
        </script>
        """)
        #expect(try await QuietPage.settles(tab, "window.rejected === true"))
    }

    @Test("A banner with only an accept button, or a reject outside any banner, is left alone")
    func neverAccepts() async throws {
        let tab = try await QuietPage.load("""
        <div class='cookie-banner'><button onclick='window.accepted = true'>Accept</button></div>
        <div class='comments'><button onclick='window.rejected = true'>Reject</button></div>
        """)
        try await Task.sleep(for: .milliseconds(900))
        #expect(try await QuietPage.value(tab, "window.accepted === undefined && window.rejected === undefined") as? Bool == true)
        #expect(tab.quietReceipt.isEmpty)
    }

    @Test("With Quiet mode off, the banner is the user's to answer")
    func offLeavesBanner() async throws {
        let tab = try await QuietPage.load(
            "<div id='consent'><button onclick='window.rejected = true'>Reject all</button></div>",
            quiets: false
        )
        try await Task.sleep(for: .milliseconds(900))
        #expect(try await QuietPage.value(tab, "window.rejected === undefined") as? Bool == true)
    }

    @Test("Sound that starts on its own is stopped; a muted background video plays on")
    func stopsAudibleAutoplay() async throws {
        // Played from the page's own script, the way an autoplaying site does.
        let source = QuietPage.silentWAV
        let tab = try await QuietPage.load("""
        <audio id='loud' loop src='\(source)'></audio><audio id='background' loop muted src='\(source)'></audio>
        <script>
        document.getElementById('background').play().catch(function () {});
        document.getElementById('loud').play().catch(function () {});
        </script>
        """)
        #expect(try await QuietPage.settlesNative { tab.quietReceipt.stoppedAutoplays == 1 })
        let loudPaused = "document.getElementById('loud').paused && !document.getElementById('background').paused"
        #expect(try await QuietPage.value(tab, loudPaused) as? Bool == true)
    }
}
