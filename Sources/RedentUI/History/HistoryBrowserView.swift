import RedentDesign
import RedentKit
import SwiftUI

/// Searchable, scoped history grouped by day. Opening remains a caller-owned
/// browser action.
///
/// Driven entirely from the search field: ↑/↓ move through the list, Return
/// opens (⌘Return in a new tab), ⌘⌫ removes the selected page.
public struct HistoryBrowserView: View {
    @State private var model: HistoryBrowserModel
    @Environment(\.dismiss) private var dismiss
    @State private var allSpaces = false
    private let initialSpaceID: UUID?
    private let onOpen: (URL, _ inNewTab: Bool) -> Void

    /// Long enough to skip the intermediate keystrokes of a word, short
    /// enough that results still feel typed-into.
    private static let searchDebounce: Duration = .milliseconds(140)

    public init(
        history: any HistoryStoring,
        spaceID: UUID? = nil,
        containerID: UUID? = nil,
        onOpen: @escaping (URL, _ inNewTab: Bool) -> Void
    ) {
        _model = State(initialValue: HistoryBrowserModel(
            history: history, spaceID: spaceID, containerID: containerID
        ))
        self.initialSpaceID = spaceID
        self.onOpen = onOpen
    }

    public var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            HistoryBrowserHeader(
                query: $model.query,
                allSpaces: $allSpaces,
                subtitle: subtitle,
                onKey: handle,
                onDone: { dismiss() }
            )
            Divider()
            HistoryBrowserList(model: model, onOpen: onOpen)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheetCanvas(width: 720, height: 540)
        .onChange(of: allSpaces) { _, all in model.spaceID = all ? nil : initialSpaceID }
        .task(id: loadKey) { await reload() }
    }

    private var loadKey: String {
        model.query + "|" + (model.spaceID?.uuidString ?? "all")
    }

    private func reload() async {
        if model.hasLoaded && model.isSearching {
            try? await Task.sleep(for: Self.searchDebounce)
            guard !Task.isCancelled else { return }
        }
        await model.load()
        if model.isSearching { model.selectedID = model.entries.first?.id }
    }

    private var subtitle: String {
        let scope = allSpaces || initialSpaceID == nil ? "every Space" : "this Space"
        return model.isSearching
            ? "\(model.entries.count) matching pages in \(scope)"
            : "Pages you have visited in \(scope), newest first."
    }

    private func handle(_ press: KeyPress) -> KeyPress.Result {
        switch press.key {
        case .downArrow: model.moveSelection(by: 1)
        case .upArrow: model.moveSelection(by: -1)
        case .return:
            guard let entry = model.selectedEntry ?? model.entries.first else { return .ignored }
            onOpen(entry.url, press.modifiers.contains(.command))
        case .delete where press.modifiers.contains(.command):
            guard let entry = model.selectedEntry else { return .ignored }
            Task { await model.delete(entry) }
        default: return .ignored
        }
        return .handled
    }
}
