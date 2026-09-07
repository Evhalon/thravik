import Foundation
import Testing
@testable import RedentImport
import RedentKit

@Suite("BookmarksJSONReader")
struct BookmarksJSONReaderTests {
    private static let validJSON = """
    {
      "roots": {
        "bookmark_bar": {
          "type": "folder",
          "name": "Bookmark Bar",
          "date_added": "13349788200000000",
          "children": [
            {
              "type": "url",
              "name": "Top Level",
              "url": "https://example.com/top",
              "date_added": "13349788200000000"
            },
            {
              "type": "folder",
              "name": "Work",
              "date_added": "13349788200000000",
              "children": [
                {
                  "type": "url",
                  "name": "Nested",
                  "url": "https://example.com/nested",
                  "date_added": "13349788200000000"
                }
              ]
            }
          ]
        },
        "other": {
          "type": "folder",
          "name": "Other Bookmarks",
          "date_added": "0",
          "children": [
            {
              "type": "url",
              "name": "Elsewhere",
              "url": "https://example.org/elsewhere",
              "date_added": "0"
            }
          ]
        }
      }
    }
    """

    private func writeFixture(_ contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "redent-bookmarks-\(UUID().uuidString).json")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @Test("flattens nested folders into folderPath, marks the bar favorite")
    func flattensAndMarksFavorites() throws {
        let url = try writeFixture(Self.validJSON)
        defer { try? FileManager.default.removeItem(at: url) }

        let bookmarks = try BookmarksJSONReader.read(from: url)
        #expect(bookmarks.count == 3)

        let topLevel = try #require(bookmarks.first { $0.title == "Top Level" })
        #expect(topLevel.folderPath == ["Bookmarks Bar"])
        #expect(topLevel.isFavorite)

        let nested = try #require(bookmarks.first { $0.title == "Nested" })
        #expect(nested.folderPath == ["Bookmarks Bar", "Work"])
        #expect(nested.isFavorite)

        let elsewhere = try #require(bookmarks.first { $0.title == "Elsewhere" })
        #expect(elsewhere.folderPath == ["Other Bookmarks"])
        #expect(!elsewhere.isFavorite)
    }

    @Test("malformed JSON throws malformedBookmarks")
    func malformedJSONThrows() throws {
        let url = try writeFixture("not json at all")
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: ImportError.malformedBookmarks) {
            try BookmarksJSONReader.read(from: url)
        }
    }

    @Test("a missing file yields no bookmarks rather than throwing")
    func missingFileYieldsEmpty() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "redent-bookmarks-missing-\(UUID().uuidString).json")
        #expect(try BookmarksJSONReader.read(from: url).isEmpty)
    }
}
