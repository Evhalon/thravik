import RedentDesign
import RedentKit
import SwiftUI

/// The scrolling body of the history sheet: day headers that stay pinned while
/// their visits scroll under them, and a selection that stays in view.
struct HistoryBrowserList: View {
    @Bindable var model: HistoryBrowserModel
    let onOpen: (URL, _ inNewTab: Bool) -> Void

    var body: some View {
        let sections = model.sections()
        if sections.isEmpty {
            if model.hasLoaded { empty }
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1, pinnedViews: .sectionHeaders) {
                        ForEach(sections) { section in
                            Section { rows(section.entries) } header: { header(section.title) }
                        }
                    }
                    .padding(.horizontal, Metric.gutter - 4)
                    .padding(.bottom, Metric.gutter)
                }
                .onChange(of: model.selectedID) { _, id in
                    guard let id else { return }
                    withAnimation(.easeOut(duration: 0.12)) { proxy.scrollTo(id) }
                }
            }
            .animation(.smooth(duration: 0.25), value: model.entries.map(\.id))
        }
    }

    private func rows(_ entries: [HistoryEntry]) -> some View {
        ForEach(entries) { entry in
            HistoryBrowserRow(
                entry: entry,
                isSelected: entry.id == model.selectedID,
                actions: .init(
                    onOpen: { onOpen(entry.url, $0) },
                    onDelete: { Task { await model.delete(entry) } },
                    onForgetSite: { forgetSite(of: entry) }
                )
            )
            .id(entry.id)
            .transition(.opacity.combined(with: .move(edge: .leading)))
        }
    }

    private func header(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11.5, weight: .semibold))
            .foregroundStyle(Palette.chromeSecondaryText)
            .padding(.horizontal, 10)
            .padding(.top, 12)
            .padding(.bottom, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.bar)
    }

    private func forgetSite(of entry: HistoryEntry) {
        guard let host = entry.origin?.displayHost else { return }
        Task { await model.clear(domain: host) }
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Image(systemName: model.isSearching ? "magnifyingglass" : "clock")
                .font(.system(size: 28, weight: .light))
            Text(model.isSearching ? "No pages match “\(model.query)”" : "No history yet")
                .font(.system(size: 13, weight: .medium))
            Text(model.isSearching ? "Try a site name or a word from the title." : "Pages you visit will appear here.")
                .font(.system(size: 11.5))
        }
        .foregroundStyle(Palette.chromeSecondaryText)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
