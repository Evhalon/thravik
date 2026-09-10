import Foundation
import Testing
@testable import RedentEngine

@Suite("Download destination")
struct DownloadDestinationTests {
    private let folder = URL(fileURLWithPath: "/Users/someone/Downloads", isDirectory: true)

    @Test("A free name is used as it stands")
    func usesSuggestedName() {
        let url = DownloadDestination.uniqueURL(for: "report.pdf", in: folder) { _ in false }
        #expect(url.lastPathComponent == "report.pdf")
    }

    @Test("A taken name is numbered rather than overwritten")
    func neverOverwrites() {
        let taken = Set(["report.pdf", "report 2.pdf"])
        let url = DownloadDestination.uniqueURL(for: "report.pdf", in: folder) {
            taken.contains($0.lastPathComponent)
        }
        #expect(url.lastPathComponent == "report 3.pdf")
    }

    @Test("An extensionless name still numbers cleanly")
    func numbersWithoutAnExtension() {
        let url = DownloadDestination.uniqueURL(for: "archive", in: folder) {
            $0.lastPathComponent == "archive"
        }
        #expect(url.lastPathComponent == "archive 2")
    }

    @Test("A fetch is staged in a folder of its own, under a safe name")
    func stagesEachFetchSeparately() throws {
        let first = try DownloadDestination.stagingURL(for: "../report.pdf")
        let second = try DownloadDestination.stagingURL(for: "report.pdf")
        defer {
            DownloadDestination.discardStaging(first)
            DownloadDestination.discardStaging(second)
        }
        #expect(first.lastPathComponent == "report.pdf")
        #expect(first.deletingLastPathComponent() != second.deletingLastPathComponent())
        #expect(FileManager.default.fileExists(atPath: first.deletingLastPathComponent().path))
    }

    @Test("Discarding a staged fetch takes its folder with it")
    func discardsTheStagingFolder() throws {
        let staged = try DownloadDestination.stagingURL(for: "report.pdf")
        let folder = staged.deletingLastPathComponent()
        DownloadDestination.discardStaging(staged)
        #expect(!FileManager.default.fileExists(atPath: folder.path))
    }

    @Test("A server-supplied name cannot escape the downloads folder")
    func sanitizesPathSeparators() {
        #expect(DownloadDestination.sanitize("../../etc/passwd") == "passwd")
        #expect(DownloadDestination.sanitize("/tmp/evil.sh") == "evil.sh")
        #expect(DownloadDestination.sanitize("..") == "download")
        #expect(DownloadDestination.sanitize("   ") == "download")
        #expect(DownloadDestination.sanitize(".hidden") == "hidden")
    }
}
