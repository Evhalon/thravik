import Foundation
import RedentKit
import Testing
@testable import RedentImport

@Suite("SQLiteDatabase")
struct SQLiteDatabaseTests {
    /// Shells out to the system `sqlite3` CLI to build a fixture database —
    /// independent of anything under test, so a bug in `SQLiteDatabase`
    /// can't hide the fixture from itself.
    private func makeFixtureDatabase() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "redent-sqlite-fixture-\(UUID().uuidString).db")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = [
            url.path,
            """
            CREATE TABLE rows (id INTEGER PRIMARY KEY, label TEXT, count INTEGER);
            INSERT INTO rows (label, count) VALUES ('alpha', 3);
            INSERT INTO rows (label, count) VALUES ('beta', 7);
            """
        ]
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
        return url
    }

    @Test("reads text and integer columns back across multiple rows")
    func readsRowsBack() throws {
        let url = try makeFixtureDatabase()
        defer { try? FileManager.default.removeItem(at: url) }

        let db = try SQLiteDatabase(readOnlyAt: url)
        var labels: [String] = []
        var counts: [Int] = []
        try db.query("SELECT label, count FROM rows ORDER BY id") { row in
            labels.append(row.text(0) ?? "")
            counts.append(row.int(1))
        }

        #expect(labels == ["alpha", "beta"])
        #expect(counts == [3, 7])
    }

    @Test("opening a nonexistent database throws databaseUnreadable")
    func missingDatabaseThrows() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "redent-sqlite-missing-\(UUID().uuidString).db")
        #expect(throws: ImportError.self) {
            _ = try SQLiteDatabase(readOnlyAt: url)
        }
    }
}
