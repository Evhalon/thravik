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

    func perform(on browser: ImportableBrowser, kinds: Set<ImportKind>) async -> Outcome {
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
                outcome.summary.bookmarks = await bookmarks.merge(saved)
            } catch { outcome.failures.append("bookmarks") }
        }
        if kinds.contains(.passwords) {
            outcome.summary.passwords = await importPasswords(from: browser, failures: &outcome.failures)
        }
        return outcome
    }

    private func importPasswords(
        from browser: ImportableBrowser,
        failures: inout [String]
    ) async -> Int {
        do {
            let found = try await importer.readPasswords(from: browser)
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
