import RedentDesign
import RedentKit
import SwiftUI

/// The split, drawn as one tab: its pages side by side in a single pill, as
/// Dia does. Clicking a half brings the split back with that page active; the
/// close mark ends the split and leaves every page as a tab of its own.
struct SplitTabRow: View {
    @Bindable var model: BrowserModel
    let namespace: Namespace.ID
    var indent: CGFloat = 0

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(model.splitTabs.enumerated()), id: \.element.id) { index, tab in
                if index > 0 { seam }
                segment(tab)
            }
            if isHovering { closeButton }
        }
        .padding(.leading, Metric.tightGutter + indent)
        .padding(.trailing, Metric.tightGutter)
        .frame(height: Metric.tabRowHeight)
        .background { background }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.14)) { isHovering = hovering }
        }
        .contextMenu { menu }
        .help("Split View — \(model.splitTabs.map(\.snapshot.displayTitle).joined(separator: " | "))")
    }

    private func segment(_ tab: any BrowserTab) -> some View {
        let isActive = model.isShowingSplit && tab.id == model.tabs.selectedID
        return TabRowLabel(tab: tab, isSelected: isActive, iconSize: 14)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { model.showSplit(focusing: tab.id) }
    }

    private var seam: some View {
        Rectangle()
            .fill(.white.opacity(0.14))
            .frame(width: Metric.hairWidth, height: Metric.tabRowHeight * 0.5)
    }

    private var closeButton: some View {
        Button { withAnimation(.spring(duration: 0.3)) { model.closeSplit() } } label: {
            ZStack {
                Circle().fill(.white.opacity(0.12)).frame(width: 17, height: 17)
                Image(systemName: "xmark")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundStyle(Palette.chromeSecondaryText)
            }
            .frame(width: 28, height: 28)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help("Close Split View — the tabs stay open")
        .transition(.scale.combined(with: .opacity))
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: Metric.tabRowHeight / 2, style: .continuous)
        if model.isShowingSplit {
            shape.fill(.white.opacity(0.13))
                .overlay { shape.strokeBorder(.white.opacity(0.18), lineWidth: Metric.hairWidth) }
                .matchedGeometryEffect(id: "tabSelection", in: namespace)
                .shadow(color: .black.opacity(0.22), radius: 7, y: 2)
        } else {
            shape.fill(.white.opacity(isHovering ? 0.09 : 0.05))
                .overlay { shape.strokeBorder(.white.opacity(0.10), lineWidth: Metric.hairWidth) }
        }
    }

    @ViewBuilder
    private var menu: some View {
        Button("Close Split View") { model.closeSplit() }
        Button("Flip Split") { model.toggleSplitOrientation() }
        Divider()
        Button("Close \(model.splitTabs.count) Tabs") { model.closeSplitTabs() }
    }
}
