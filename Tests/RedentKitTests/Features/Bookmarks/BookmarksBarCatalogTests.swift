import Foundation
import Testing
@testable import RedentKit

@Suite("Bookmarks bar catalog")
struct BookmarksBarCatalogTests {
    private let work = BrowserSpace.workID
    private let personal = BrowserSpace.personalID

    @Test("Only the current Space's top-level pages appear")
    func scopesToCurrentSpace() throws {
        let items = BookmarksBarCatalog.items(
            bookmarks: [
                Bookmark(url: try url("https://work.example"), title: "Work", spaceID: work),
                Bookmark(url: try url("https://home.example"), title: "Home", spaceID: personal)
            ],
            folders: [],
            spaceID: work
        )
        #expect(titles(items) == ["Work"])
    }

    @Test("Imported Bookmarks Bar pages count as top-level; Other Bookmarks do not")
    func importedBarPages() throws {
        let items = BookmarksBarCatalog.items(
            bookmarks: [
                Bookmark(
                    url: try url("https://bar.example"), title: "Bar",
                    folderPath: ["Bookmarks Bar"], spaceID: work
                ),
                Bookmark(
                    url: try url("https://other.example"), title: "Other",
                    folderPath: ["Other Bookmarks"], spaceID: work
                )
            ],
            folders: [],
            spaceID: work
        )
        #expect(titles(items) == ["Bar"])
    }

    @Test("A native folder becomes a dropdown of its pages")
    func nativeFolderDropdown() throws {
        let folder = BookmarkFolder(path: ["Reading"], spaceID: work)
        let child = Bookmark(
            url: try url("https://read.example"), title: "Essay",
            folderPath: ["Reading"], spaceID: work
        )
        let items = BookmarksBarCatalog.items(
            bookmarks: [child], folders: [folder], spaceID: work
        )
        guard case .folder(let record, let pages) = items.first else {
            Issue.record("expected a folder chip")
            return
        }
        #expect(record.path == ["Reading"])
        #expect(pages.map(\.title) == ["Essay"])
    }

    @Test("A bookmark's folder path is enough to mint a bar folder")
    func implicitFolder() throws {
        let items = BookmarksBarCatalog.items(
            bookmarks: [
                Bookmark(
                    url: try url("https://docs.example"), title: "Docs",
                    folderPath: ["Docs"], spaceID: work
                )
            ],
            folders: [],
            spaceID: work
        )
        #expect(items.count == 1)
        guard case .folder(_, let pages) = items.first else {
            Issue.record("expected an implicit folder")
            return
        }
        #expect(pages.map(\.title) == ["Docs"])
    }

    @Test("Pages filed only in a subfolder still surface their top-level folder")
    func nestedOnlyFolder() throws {
        let items = BookmarksBarCatalog.items(
            bookmarks: [
                Bookmark(url: try url("https://a.example"), title: "Deep", folderPath: ["Work", "Specs"], spaceID: work),
                Bookmark(
                    url: try url("https://b.example"), title: "Imported",
                    folderPath: ["Bookmarks Bar", "News", "Daily"], spaceID: work
                ),
                Bookmark(url: try url("https://c.example"), title: "Hidden", folderPath: ["Other Bookmarks", "X"], spaceID: work)
            ],
            folders: [],
            spaceID: work
        )
        let folders = items.compactMap { item -> ([String], [String])? in
            guard case .folder(let folder, let pages) = item else { return nil }
            return (folder.path, pages.map(\.title))
        }
        #expect(folders.map(\.0) == [["Bookmarks Bar", "News"], ["Work"]])
        #expect(folders.map(\.1) == [["Imported"], ["Deep"]])
    }

    @Test("Only the first rank of a path becomes a chip")
    func barFolderPaths() {
        #expect(BookmarksBarCatalog.barFolderPath(containing: ["Work", "Specs"]) == ["Work"])
        #expect(BookmarksBarCatalog.barFolderPath(containing: ["Bookmarks Bar", "A", "B"]) == ["Bookmarks Bar", "A"])
        #expect(BookmarksBarCatalog.barFolderPath(containing: ["Bookmarks Bar"]) == nil)
        #expect(BookmarksBarCatalog.barFolderPath(containing: ["Synced", "A"]) == nil)
        #expect(BookmarksBarCatalog.barFolderPath(containing: []) == nil)
    }

    @Test("No Space means an empty bar")
    func missingSpace() throws {
        let items = BookmarksBarCatalog.items(
            bookmarks: [Bookmark(url: try url("https://a.example"), spaceID: work)],
            folders: [],
            spaceID: nil
        )
        #expect(items.isEmpty)
    }

    private func url(_ text: String) throws -> URL { try #require(URL(string: text)) }

    private func titles(_ items: [BookmarksBarItem]) -> [String] {
        items.map(\.title)
    }
}
