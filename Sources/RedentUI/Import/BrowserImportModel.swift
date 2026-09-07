import Foundation
import Observation
import RedentKit

/// Runs an import from another browser and reports what came across.
@MainActor @Observable
public final class BrowserImportModel {
    public private(set) var browsers: [ImportableBrowser] = []
    public var selectedID: String?
    public var kinds: Set<ImportKind> = [.history, .bookmarks, .passwords]
    public private(set) var isRunning = false
    public private(set) var summary: ImportSummary?
    /// Set when part of the import failed. The rest still went through.
    public private(set) var problem: String?

    private let importer: any BrowserImporting
    private let history: any HistoryStoring
    private let bookmarks: any BookmarkStoring
    private let credentials: any CredentialStoring

    public init(
        importer: any BrowserImporting,
        history: any HistoryStoring,
        bookmarks: any BookmarkStoring,
        credentials: any CredentialStoring
    ) {
        self.importer = importer
        self.history = history
        self.bookmarks = bookmarks
        self.credentials = credentials
    }

    public var selected: ImportableBrowser? {
        browsers.first { $0.id == selectedID }
    }

    public var canRun: Bool { selected != nil && !kinds.isEmpty && !isRunning }

    public func discover() {
        browsers = importer.availableBrowsers()
        selectedID = selectedID ?? browsers.first?.id
    }

    public func toggle(_ kind: ImportKind) {
        if kinds.contains(kind) { kinds.remove(kind) } else { kinds.insert(kind) }
    }

    public func run() async {
        guard let browser = selected, !isRunning else { return }
        isRunning = true
        problem = nil
        summary = nil
        defer { isRunning = false }

        var result = ImportSummary()
        var failures: [String] = []

        if kinds.contains(.history) {
            do {
                let entries = try await importer.readHistory(from: browser)
                await history.merge(entries)
                result.history = entries.count
            } catch { failures.append("history") }
        }
        if kinds.contains(.bookmarks) {
            do {
                let saved = try await importer.readBookmarks(from: browser)
                result.bookmarks = await bookmarks.merge(saved)
            } catch { failures.append("bookmarks") }
        }
        if kinds.contains(.passwords) {
            result.passwords = await importPasswords(from: browser, failures: &failures)
        }

        summary = result
        problem = failures.isEmpty ? nil : Self.message(for: failures)
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
        } catch ImportError.databaseUnreadable(_) {
            failures.append("passwords-locked")
            return 0
        } catch {
            failures.append("passwords-save")
            return 0
        }
    }

    static func message(for failures: [String]) -> String {
        if failures.contains("passwords-key") {
            return "Passwords need permission: macOS must allow Redent to read the other browser's encryption key from your Keychain. Try again and choose Allow."
        }
        if failures.contains("passwords-save") {
            return "Passwords were read but could not be saved to the Keychain."
        }
        if failures.contains("passwords-locked") {
            return "Could not open the password file. Quit the other browser and try again."
        }
        if failures.contains("passwords") {
            return "Could not read passwords from the other browser."
        }
        return "Could not read: \(failures.joined(separator: ", ")). The other browser may be running — quit it and try again."
    }
}
