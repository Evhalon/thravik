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
    /// The text the current rows were ranked for; the row view bolds it.
    public private(set) var query = ""
    /// Index of the row the user arrowed onto. `nil` means return follows
    /// row 0, which always mirrors the field's own text.
    public var highlighted: Int?
    /// The field the open list belongs to; `nil` when nothing is open.
    public private(set) var openSource: Source?
    /// The completion the owning field should select after the caret.
    public private(set) var completion: InlineCompletion?

    private let engine: SuggestionEngine
    @ObservationIgnored private var pending: Task<Void, Never>?
    /// The last text the user typed themselves, completions excluded.
    @ObservationIgnored private var lastTyped = ""

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

    /// What return opens for `text`: the row the user arrowed onto, or the
    /// completion the field is showing. `nil` means resolve the text itself.
    public func submission(for text: String) -> AddressSuggestion? {
        if let highlightedRow { return highlightedRow }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let completion, completion.text == trimmed, rows.first?.url == completion.url else { return nil }
        return rows.first
    }

    public func isOpen(for source: Source) -> Bool { openSource == source }

    public func update(query: String, from source: Source, context: SuggestionContext) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        // The field echoes a completion back as if it were typed.
        if openSource == source, let completion, completion.text == trimmed { return }
        pending?.cancel()
        guard !trimmed.isEmpty else { return close() }

        // Only a longer text earns a completion: after a backspace, putting
        // the removed characters straight back would make deleting impossible.
        let allowsCompletion = trimmed.count > lastTyped.count
        lastTyped = trimmed
        pendingSource = source
        pending = Task { [engine] in
            try? await Task.sleep(for: .milliseconds(30))
            guard !Task.isCancelled else { return }
            let found = await engine.suggestions(for: trimmed, context: context, allowsCompletion: allowsCompletion)
            guard !Task.isCancelled else { return }
            rows = found.rows
            self.query = trimmed
            completion = found.completion
            openSource = found.rows.isEmpty ? nil : source
            highlighted = nil
            pendingSource = nil
        }
    }

    public func close() {
        pending?.cancel()
        pending = nil
        pendingSource = nil
        rows = []
        query = ""
        highlighted = nil
        openSource = nil
        completion = nil
        lastTyped = ""
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
        guard let current = highlighted else {
            highlighted = offset > 0 ? 0 : rows.count - 1
            return
        }
        highlighted = (current + offset + rows.count) % rows.count
    }
}
