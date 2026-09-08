import Foundation
import Testing
@testable import RedentUpdate

@Suite("GitHub release feed")
struct ReleaseFeedPayloadTests {
    @Test("A published release with a disk image is offered")
    func acceptsPublishedRelease() throws {
        let release = try decode(Self.feed()).release()
        #expect(release.version.description == "0.1.2")
        #expect(release.downloadURL.absoluteString.hasSuffix("Thravik-macOS.dmg"))
        #expect(release.pageURL != nil)
    }

    @Test("Drafts and pre-releases are not offered")
    func rejectsUnpublished() throws {
        #expect(throws: UpdateError.noPublishedRelease) {
            try decode(Self.feed(draft: true)).release()
        }
        #expect(throws: UpdateError.noPublishedRelease) {
            try decode(Self.feed(prerelease: true)).release()
        }
    }

    @Test("A release without a disk image is not offered")
    func rejectsMissingImage() throws {
        #expect(throws: UpdateError.noDiskImage) {
            try decode(Self.feed(asset: "Thravik-macOS.zip")).release()
        }
    }

    @Test("A plain-http download would let anyone on the path ship code")
    func rejectsInsecureDownload() throws {
        #expect(throws: UpdateError.insecureDownload) {
            try decode(Self.feed(scheme: "http")).release()
        }
    }

    @Test("A tag this app cannot compare is not treated as newer")
    func rejectsUncomparableTag() throws {
        #expect(throws: UpdateError.unreadableVersion("nightly")) {
            try decode(Self.feed(tag: "nightly")).release()
        }
    }

    private func decode(_ json: String) throws -> ReleaseFeedPayload {
        let data = try #require(json.data(using: .utf8))
        return try JSONDecoder().decode(ReleaseFeedPayload.self, from: data)
    }

    private static func feed(
        tag: String = "v0.1.2",
        draft: Bool = false,
        prerelease: Bool = false,
        asset: String = "Thravik-macOS.dmg",
        scheme: String = "https"
    ) -> String {
        """
        {
          "tag_name": "\(tag)",
          "html_url": "https://github.com/Evhalon/thravik/releases/tag/\(tag)",
          "draft": \(draft),
          "prerelease": \(prerelease),
          "assets": [
            {"name": "\(asset)",
             "browser_download_url": "\(scheme)://github.com/Evhalon/thravik/releases/download/\(tag)/\(asset)"}
          ]
        }
        """
    }
}
