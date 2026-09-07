import RedentDesign
import RedentKit
import SwiftUI

/// Searchable, scoped history list. Opening remains a caller-owned browser action.
public struct HistoryBrowserView: View {
    @State private var model: HistoryBrowserModel
    @Environment(\.dismiss) private var dismiss
    @State private var allSpaces = false
    private let initialSpaceID: UUID?
    private let onOpen: (URL) -> Void

    public init(
        history: any HistoryStoring,
        spaceID: UUID? = nil,
        containerID: UUID? = nil,
        onOpen: @escaping (URL) -> Void
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
            HStack {
                Text("History").font(.system(size: 15, weight: .semibold))
                Toggle("All Spaces", isOn: $allSpaces)
                    .onChange(of: allSpaces) { _, all in model.spaceID = all ? nil : initialSpaceID }
                Spacer()
                Button("Done") { dismiss() }
                TextField("Search history", text: $model.query)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 230)
            }
            .padding(Metric.gutter)
            Divider()
            content
        }
        .frame(minWidth: 680, minHeight: 460)
        .sheetCanvas(width: 760, height: 560)
        .task(id: model.query + (model.spaceID?.uuidString ?? "")) { await model.load() }
    }

    @ViewBuilder
    private var content: some View {
        if model.entries.isEmpty && !model.isLoading {
            VStack(spacing: 7) {
                Image(systemName: "clock").font(.system(size: 26, weight: .light))
                Text(model.query.isEmpty ? "No history yet" : "No matching pages")
                    .font(.system(size: 12))
            }
            .foregroundStyle(Palette.chromeSecondaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(model.entries) { entry in
                HistoryBrowserRow(
                    entry: entry,
                    onOpen: { onOpen(entry.url) },
                    onDelete: { Task { await model.delete(entry) } }
                )
            }
            .listStyle(.inset)
        }
    }
}
