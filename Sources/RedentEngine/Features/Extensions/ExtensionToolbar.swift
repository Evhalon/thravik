import AppKit
import SwiftUI

/// The puzzle-piece button in a window's toolbar, there once at least one
/// extension is installed. It opens the list of extensions; picking one runs
/// its button — usually its popup, pointed at the puzzle piece.
public struct ExtensionToolbar: View {
    private let host: ExtensionHost
    private let tabs: TabController
    private let onManage: () -> Void
    @State private var isShowingList = false
    @State private var anchor = ExtensionAnchor()

    public init(host: ExtensionHost, tabs: TabController, onManage: @escaping () -> Void) {
        self.host = host
        self.tabs = tabs
        self.onManage = onManage
    }

    public var body: some View {
        if !host.installed.isEmpty {
            Button { isShowingList.toggle() } label: {
                Image(systemName: "puzzlepiece.extension")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28, height: 28)
                    .contentShape(.rect)
                    .overlay(alignment: .topTrailing) { badgeDot }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Extensions")
            .accessibilityLabel("Extensions")
            .background(ExtensionAnchorReader(anchor: anchor))
            .popover(isPresented: $isShowingList, arrowEdge: .bottom) {
                ExtensionList(items: host.toolbarItems(in: tabs), onPick: pick, onOptions: openOptions, onManage: manage)
            }
        }
    }

    /// A badge on any extension shows as a dot here, so it is not missed.
    @ViewBuilder
    private var badgeDot: some View {
        if host.toolbarItems(in: tabs).contains(where: { !$0.badge.isEmpty }) {
            Circle().fill(Color.accentColor).frame(width: 6, height: 6).offset(x: -3, y: 4)
        }
    }

    /// The list closes first; an extension popup opened on top of a closing
    /// popover is dismissed along with it.
    private func pick(_ item: ExtensionToolbarItem) {
        isShowingList = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            guard let view = anchor.view else { return }
            host.performAction(item.id, in: tabs, anchor: view)
        }
    }

    private func openOptions(_ item: ExtensionToolbarItem) {
        isShowingList = false
        host.openOptions(for: item.id)
    }

    private func manage() {
        isShowingList = false
        onManage()
    }
}
