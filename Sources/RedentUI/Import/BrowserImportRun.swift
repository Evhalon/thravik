import Foundation
import RedentKit

/// Imports one browser profile. Split out from `BrowserImportModel` so the
/// model only has to walk the selection and add the results up.
@MainActor
struct BrowserImportRun {
    struct Outcome {
        var summary = ImportSummary()
        var failures: [String] = []
    }

    let importer: any BrowserImporting
    let history: any HistoryStoring
    let bookmarks: any BookmarkStoring
    let credentials: any CredentialStoring

    func perform(on browser: ImportableBrowser, kinds: Set<ImportKind>, spaceID: UUID?) async -> Outcome {
        var outcome = Outcome()
        if kinds.contains(.history) {
            do {
                let entries = try await importer.readHistory(from: browser)
                await history.merge(entries)
                outcome.summary.history = entries.count
            } catch { outcome.failures.append("history") }
        }
        if kinds.contains(.bookmarks) {
            do {
                let saved = try await importer.readBookmarks(from: browser)
                outcome.summary.bookmarks = await bookmarks.merge(saved.map { adopted($0, by: spaceID) })
            } catch { outcome.failures.append("bookmarks") }
        }
        if kinds.contains(.passwords) {
            outcome.summary.passwords = await importPasswords(
                from: browser, spaceID: spaceID, failures: &outcome.failures
            )
        }
        return outcome
    }

    /// The imported page joins the receiving Space, not the one it came from.
    private func adopted(_ bookmark: Bookmark, by spaceID: UUID?) -> Bookmark {
        var result = bookmark
        result.spaceID = spaceID
        return result
    }

    private func importPasswords(
        from browser: ImportableBrowser,
        spaceID: UUID?,
        failures: inout [String]
    ) async -> Int {
        do {
            let found = try await importer.readPasswords(from: browser).map { credential in
                var adopted = credential
                adopted.spaceID = spaceID
                return adopted
            }
            return try await credentials.importCredentials(found).count
        } catch ImportError.decryptionKeyUnavailable {
            failures.append("passwords-key")
            return 0
        } catch ImportError.databaseUnreadable {
            failures.append("passwords-locked")
            return 0
        } catch {
            failures.append("passwords-save")
            return 0
        }
    }
}
