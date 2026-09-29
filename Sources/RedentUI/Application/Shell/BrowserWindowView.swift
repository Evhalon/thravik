import AppKit
import RedentDesign
import SwiftUI

/// One browser window: a single glass slab, with the page floating on it.
///
/// The window has no chrome above its own first row — the toolbar shares that
/// line with the window buttons, and everything below it is page.
///
/// Modal screens arrive through `sheetContent` so this view stays independent
/// of the concrete vault and scanner screens.
public struct BrowserWindowView<Sheets: View>: View {
    @Bindable private var model: BrowserModel
    private let sheetContent: (SheetRoute) -> Sheets

    public init(model: BrowserModel, @ViewBuilder sheetContent: @escaping (SheetRoute) -> Sheets) {
        self.model = model
        self.sheetContent = sheetContent
    }

    public var body: some View {
        ZStack {
            windowBackdrop
            BrowserWorkspace(model: model, backdrop: windowBackdrop)
        }
        .coordinateSpace(WindowBackdrop.space)
        .clipped()
        .environment(\.ambientTint, ambientTint)
        .modifier(AddressSuggestionsPresenter(model: model))
        .overlay(alignment: .top) { commandBar }
        .overlay(alignment: .bottom) { expiryBar }
        .onChange(of: model.selectedTab?.url) { _, _ in
            model.pageContextChanged()
            model.address.sync(with: model.selectedTab)
        }
        .task(id: model.selectedTab?.url) { await model.refreshBookmarkState() }
        .onChange(of: model.tabs.selectedID) { _, _ in
            model.pageContextChanged()
            model.address.syncSelection(with: model.selectedTab)
        }
        .alert("Action unavailable", isPresented: Binding(
            get: { model.actionError != nil }, set: { if !$0 { model.actionError = nil } }
        )) { Button("OK") { model.actionError = nil } } message: { Text(model.actionError ?? "") }
        .sheet(item: $model.sheet, content: sheetContent)
        // Menu commands act on the window in front, never on whichever one the
        // app happened to build first.
        .focusedSceneValue(\.browserModel, model)
        .task(runClock)
        .onDisappear(perform: model.persistSession)
    }

    @ViewBuilder
    private var commandBar: some View {
        if model.showsCommandBar {
            ZStack(alignment: .top) {
                Color.black.opacity(0.18).onTapGesture { model.dismissCommands() }
                CommandBarView(model: model.commandBar, onDismiss: model.dismissCommands)
                    .padding(.top, 72)
            }
        }
    }

    @ViewBuilder
    private var expiryBar: some View {
        if let id = model.expiredTabID,
           let tab = model.tabs.tabs.first(where: { $0.id == id }) {
            TemporaryTabBar(
                title: tab.snapshot.displayTitle,
                onKeep: model.keepExpiredTab,
                onClose: model.closeExpiredTab
            )
            .padding(Metric.gutter)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var windowBackdrop: some View {
        ZStack(alignment: .top) {
            WindowBackdrop(tint: ambientTint).equatable()
            SpaceWash(space: model.currentSpace)
                .animation(.easeInOut(duration: 0.34), value: model.currentSpaceID)
        }
    }

    /// The chrome takes its color from the site's favicon, which is reliably
    /// the brand color; a declared `theme-color` is used only when the favicon
    /// yields nothing, and Redent's own hue when neither does. A private window
    /// keeps its own hue throughout, so it is never mistaken for a normal one.
    private var ambientTint: Color? {
        guard !model.isPrivate else { return Palette.privateAmbient }
        guard let tab = model.selectedTab else { return Palette.defaultAmbient }
        return DominantColor.extract(from: tab.snapshot.faviconData)
            ?? Palette.defaultAmbient
    }

    /// One clock for the window: TOTP countdowns, address sync, and the
    /// hibernation sweep all ride on it (AGENTS.md §4).
    @Sendable private func runClock() async {
        while !Task.isCancelled {
            model.tick(.now)
            // Nothing is counting down on screen while another app is in front.
            // The hibernation sweep still has to run — that is precisely when it
            // matters — but it does not need a heartbeat every second.
            try? await Task.sleep(for: NSApp.isActive ? .seconds(1) : .seconds(5))
        }
    }
}
