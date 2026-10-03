import Foundation
import Testing
@testable import RedentKit

struct SyncWorkspaceSnapshotTests {
    @Test func excludesTemporaryTabsRuntimeStateAndSensitiveURLComponents() throws {
        let url = try #require(URL(string: "https://user:password@example.com/page?token=secret#private"))
        let file = try #require(URL(string: "file:///Users/user/private.txt"))
        var normal = TabSnapshot(url: url, title: "Page", faviconData: Data("favicon".utf8))
        normal.pinnedURL = url
        let temporary = TabSnapshot(url: url, expiresAt: .distantFuture)
        let local = TabSnapshot(url: file)
        let session = BrowserSession(tabs: [normal, temporary, local])
        let snapshot = SyncWorkspaceSnapshot(session: session, deviceID: UUID())
        #expect(snapshot.tabs.count == 2)
        #expect(snapshot.tabs[0].url?.absoluteString == "https://example.com/page")
        #expect(snapshot.tabs[0].pinnedURL?.absoluteString == "https://example.com/page")
        #expect(snapshot.tabs[1].url == nil)
        #expect(snapshot.spaces.allSatisfy { $0.selectedTabID == nil })
        #expect(!snapshot.spaces.flatMap(\.tabIDs).contains(temporary.id))
        let encoded = try JSONEncoder().encode(snapshot)
        let json = String(decoding: encoded, as: UTF8.self)
        #expect(!json.contains("secret"))
        #expect(!json.contains("favicon"))
        #expect(!json.contains("timeline"))
    }
}
