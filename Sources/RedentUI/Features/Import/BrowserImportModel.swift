import Foundation
import Observation
import RedentKit

/// Imports browser profiles independently and reports their combined counts.
@MainActor @Observable
public final class BrowserImportModel {
    public private(set) var browsers: [ImportableBrowser] = []
    public private(set) var selectedIDs: Set<String> = []
    public var kinds: Set<ImportKind> = [.history, .bookmarks, .passwords]
    public private(set) var isRunning = false
    /// The profile currently being read, so a multi-profile run shows progress.
    public private(set) var runningBrowserName: String?
    public private(set) var summary: ImportSummary?
    /// Set when part of the import failed. The rest still went through.
    public private(set) var problem: String?
    @ObservationIgnored public var onComplete: (@MainActor (BrowserImportReceipt) -> Void)?

    /// Bookmarks are scoped; history and password access remain global.
    public var destination: ImportDestination
    public var createsSpacePerProfile = true
    @ObservationIgnored public var createSpace: (@MainActor (String) async throws -> UUID)?

    private let importer: any BrowserImporting
    private let run: BrowserImportRun
    private var profileSpaceIDs: [String: UUID] = [:]
    private var didFailSpaceCreation = false

    public init(
        importer: any BrowserImporting,
        history: any HistoryStoring,
        bookmarks: any BookmarkStoring,
        credentials: any CredentialStoring,
        destination: ImportDestination
    ) {
        self.importer = importer
        self.destination = destination
        run = BrowserImportRun(
            importer: importer,
            history: history,
            bookmarks: bookmarks,
            credentials: credentials
        )
    }

    /// Selected profiles, in the order they are shown.
    public var selectedBrowsers: [ImportableBrowser] {
        browsers.filter { selectedIDs.contains($0.id) }
    }

    public var canRun: Bool { !selectedIDs.isEmpty && !kinds.isEmpty && !isRunning }
    public var isEverythingSelected: Bool {
        !browsers.isEmpty && selectedIDs.count == browsers.count
    }

    public func discover() {
        browsers = importer.availableBrowsers()
        let known = Set(browsers.map(\.id))
        selectedIDs.formIntersection(known)
        if selectedIDs.isEmpty { selectAll() }
    }

    public func toggle(browserID: String) {
        if selectedIDs.contains(browserID) {
            selectedIDs.remove(browserID)
        } else {
            selectedIDs.insert(browserID)
        }
    }

    public func selectAll() { selectedIDs = Set(browsers.map(\.id)) }
    public func deselectAll() { selectedIDs.removeAll() }

    public func toggle(_ kind: ImportKind) {
        if kinds.contains(kind) { kinds.remove(kind) } else { kinds.insert(kind) }
    }

    public func run() async {
        let targets = selectedBrowsers
        guard !targets.isEmpty, !kinds.isEmpty, !isRunning else { return }
        isRunning = true
        problem = nil
        summary = nil
        defer {
            isRunning = false
            runningBrowserName = nil
        }

        var total = ImportSummary()
        var failures: [String] = []
        for browser in targets {
            runningBrowserName = browser.name
            guard let spaceID = await destinationID(for: browser) else {
                if didFailSpaceCreation { failures.append("space-create") }
                continue
            }
            let outcome = await run.perform(on: browser, kinds: kinds, spaceID: spaceID)
            total.add(outcome.summary)
            failures.append(contentsOf: outcome.failures)
        }

        summary = total
        problem = failures.isEmpty ? nil : Self.message(for: failures)
        onComplete?(BrowserImportReceipt(summary: total, profileNames: targets.map(\.name), problem: problem))
    }

    static func message(for failures: [String]) -> String {
        if failures.contains("space-create") {
            return "Could not create a Space for one or more profiles. Those profiles were skipped; other profiles continued."
        }
        if failures.contains("passwords-key") {
            return "Passwords need permission: macOS must allow Thravik to read the other browser's encryption key. Try again and choose Always Allow to retain that permission."
        }
        if failures.contains("passwords-save") {
            return "Passwords were read but could not be saved to the Keychain."
        }
        if failures.contains("passwords-locked") {
            return "Some password archives could not be read. Successfully imported data is kept. Close the source browser and retry, or import passwords separately."
        }
        if failures.contains("passwords") {
            return "Could not read passwords from the other browser."
        }
        var seen: Set<String> = []
        let kinds = failures.filter { seen.insert($0).inserted }
        return "Could not read: \(kinds.joined(separator: ", ")). The other browser may be running — quit it and try again."
    }

    private func destinationID(for browser: ImportableBrowser) async -> UUID? {
        didFailSpaceCreation = false
        guard createsSpacePerProfile else { return destination.spaceID }
        if let existing = profileSpaceIDs[browser.id] { return existing }
        guard let createSpace else {
            didFailSpaceCreation = true
            return nil
        }
        do {
            let created = try await createSpace(browser.name)
            profileSpaceIDs[browser.id] = created
            return created
        } catch {
            didFailSpaceCreation = true
            return nil
        }
    }
}
