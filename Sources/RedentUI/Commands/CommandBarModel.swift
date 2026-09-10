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
    private let searchEngine: SearchEngine
    private let descriptors: [CommandDescriptor]
    @ObservationIgnored private var pending: Task<Void, Never>?
    private var generation = 0
    private var selectionRevision = 0

    /// Lets tests await the in-flight search rather than race the debounce.
    var searchInFlight: Task<Void, Never>? { pending }
    public struct Configuration {
        public var history: any HistoryStoring
        public var bookmarks: any BookmarkStoring
        public var context: CommandBarContext
        public var searchEngine: SearchEngine
        public var descriptors: [CommandDescriptor]
        public var onExecute: ActionHandler?

        public init(history: any HistoryStoring, bookmarks: any BookmarkStoring) {
            self.history = history
            self.bookmarks = bookmarks
            self.context = .init()
            self.searchEngine = .duckduckgo
            self.descriptors = DefaultCommandDescriptors.all
            self.onExecute = nil
        }

    }

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

    public func executeSelected() async {
        guard let selectedRow else { return }
        await execute(selectedRow)
    }
    public func execute(_ row: CommandBarResult) async {
        guard let action = row.action, isValid(action), let onExecute else { return }
        await onExecute(action)
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
            rows = CommandSearchResults.empty(context: context, descriptors: descriptors)
            selectedIndex = rows.isEmpty ? nil : 0
            return
        }
        pending = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(90))
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

private enum CommandSearchResults {
    static func empty(context: CommandBarContext, descriptors: [CommandDescriptor]) -> [CommandBarResult] {
        descriptors.compactMap { descriptor in
            guard let action = descriptor.action(in: context, query: "") else { return nil }
            return CommandBarResult(id: "command:\(descriptor.id)", title: descriptor.title,
                                    subtitle: "Command", source: .command, action: action)
        }
    }
}
