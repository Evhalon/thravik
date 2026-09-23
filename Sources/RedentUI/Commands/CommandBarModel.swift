import Foundation
import Observation
import RedentKit
@MainActor @Observable
public final class CommandBarModel {
    public typealias ActionHandler = @MainActor @Sendable (BrowserAction) async -> Void

    public var query: String = "" {
        didSet { scheduleSearch() }
    }
    public private(set) var rows: [CommandBarResult] = []
    public private(set) var context: CommandBarContext
    public var selectedIndex: Int?
    public var onExecute: ActionHandler?

    private let history: any HistoryStoring
    private let bookmarks: any BookmarkStoring
    /// Follows Settings, so a query searches wherever the user last chose.
    public var searchEngine: SearchEngine
    private let descriptors: [CommandDescriptor]
    @ObservationIgnored private var pending: Task<Void, Never>?
    private var generation = 0
    private var selectionRevision = 0

    /// Lets tests await the in-flight search rather than race the debounce.
    var searchInFlight: Task<Void, Never>? { pending }
    public init(configuration: Configuration) {
        history = configuration.history
        bookmarks = configuration.bookmarks
        context = configuration.context
        searchEngine = configuration.searchEngine
        descriptors = configuration.descriptors
        onExecute = configuration.onExecute
    }

    public convenience init(
        history: any HistoryStoring,
        bookmarks: any BookmarkStoring,
        context: CommandBarContext = .init(),
        searchEngine: SearchEngine = .duckduckgo,
        descriptors: [CommandDescriptor] = DefaultCommandDescriptors.all
    ) {
        var configuration = Configuration(history: history, bookmarks: bookmarks)
        configuration.context = context
        configuration.searchEngine = searchEngine
        configuration.descriptors = descriptors
        self.init(configuration: configuration)
    }
    public var selectedRow: CommandBarResult? {
        guard let selectedIndex, rows.indices.contains(selectedIndex) else { return nil }
        return rows[selectedIndex]
    }

    public func updateContext(_ context: CommandBarContext) {
        self.context = context
        scheduleSearch()
    }
    public func moveSelection(by offset: Int) {
        guard !rows.isEmpty else { return }
        let current = selectedIndex ?? 0
        selectedIndex = (current + offset + rows.count) % rows.count
        selectionRevision += 1
    }

    /// - Returns: whether the bar is done — false when the row only filled
    ///   the field and is waiting for its argument.
    @discardableResult
    public func executeSelected() async -> Bool {
        let submittedGeneration = generation
        await pending?.value
        guard generation == submittedGeneration else { return false }
        guard let selectedRow else { return true }
        return await execute(selectedRow)
    }

    /// ⌘1…⌘9 while the bar is open: run the row at that position.
    @discardableResult
    public func executeRow(at position: Int) async -> Bool {
        await pending?.value
        guard rows.indices.contains(position - 1) else { return false }
        return await execute(rows[position - 1])
    }

    @discardableResult
    public func execute(_ row: CommandBarResult) async -> Bool {
        if let completion = row.completion {
            query = completion
            return false
        }
        guard let action = row.action, isValid(action), let onExecute else { return true }
        await onExecute(action)
        return true
    }

    public func close() {
        pending?.cancel()
        pending = nil
        rows = []
        selectedIndex = nil
    }

    private func scheduleSearch() {
        pending?.cancel()
        generation += 1
        let request = generation
        let query = query
        let context = context
        let history = history
        let bookmarks = bookmarks
        let descriptors = descriptors
        let searchEngine = searchEngine
        let initialSelectionRevision = selectionRevision
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            rows = CommandHome.rows(context: context, descriptors: descriptors)
            selectedIndex = rows.isEmpty ? nil : 0
            return
        }
        pending = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(30))
            guard !Task.isCancelled else { return }
            let source = CommandSearch.Source(descriptors: descriptors, history: history,
                bookmarks: bookmarks, searchEngine: searchEngine)
            let found = await CommandSearch.results(query: query, context: context, source: source, limit: 30)
            guard !Task.isCancelled, let self, self.generation == request,
                  self.query == query else { return }
            self.rows = found
            self.selectedIndex = found.isEmpty ? nil
                : self.selectionRevision == initialSelectionRevision ? 0
                : min(self.selectedIndex ?? 0, found.count - 1)
        }
    }

    private func isValid(_ action: BrowserAction) -> Bool {
        CommandValidity.isValid(action, in: context)
    }
}
