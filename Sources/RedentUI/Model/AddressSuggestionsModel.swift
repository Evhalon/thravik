import Foundation
import Observation
import RedentKit

/// Drives the address bar dropdown: what to show, and which row is armed.
///
/// Queries are debounced. Typing at speed would otherwise fire a SQLite search
/// per keystroke, and the answer to a prefix the user has already moved past is
/// wasted work.
@MainActor @Observable
public final class AddressSuggestionsModel {
    /// Which field a dropdown belongs to. The address bar and the new tab's
    /// search field share this model and are on screen together, so an open
    /// list has to name its owner or it draws under both at once.
    public enum Source: Sendable {
        case addressBar
        case newTab
    }

    public private(set) var rows: [AddressSuggestion] = []
    /// Index of the row that return will open. `nil` means "use the raw text".
    public var highlighted: Int?
    /// The field the open list belongs to; `nil` when nothing is open.
    public private(set) var openSource: Source?

    private let engine: SuggestionEngine
    @ObservationIgnored private var pending: Task<Void, Never>?

    /// Lets tests await the in-flight query rather than race the debounce.
    var queryInFlight: Task<Void, Never>? { pending }
    private var pendingSource: Source?

    public init(engine: SuggestionEngine) {
        self.engine = engine
    }

    public var highlightedRow: AddressSuggestion? {
        guard let highlighted, rows.indices.contains(highlighted) else { return nil }
        return rows[highlighted]
    }

    public func isOpen(for source: Source) -> Bool { openSource == source }

    public func update(query: String, from source: Source, searchEngine: SearchEngine, spaceID: UUID?) {
        pending?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return close() }

        pendingSource = source
        pending = Task { [engine] in
            try? await Task.sleep(for: .milliseconds(90))
            guard !Task.isCancelled else { return }
            let found = await engine.suggestions(for: trimmed, engine: searchEngine, spaceID: spaceID)
            guard !Task.isCancelled else { return }
            rows = found
            openSource = found.isEmpty ? nil : source
            highlighted = found.isEmpty ? nil : 0
            pendingSource = nil
        }
    }

    public func close() {
        pending?.cancel()
        pending = nil
        pendingSource = nil
        rows = []
        highlighted = nil
        openSource = nil
    }

    /// Closes only what this field owns. A field losing focus must not tear down
    /// a list the field taking focus has just opened — the two blur/focus events
    /// arrive in no guaranteed order.
    public func close(from source: Source) {
        guard openSource == source || pendingSource == source else { return }
        close()
    }

    public func moveHighlight(by offset: Int) {
        guard openSource != nil, !rows.isEmpty else { return }
        let current = highlighted ?? 0
        highlighted = (current + offset + rows.count) % rows.count
    }
}
