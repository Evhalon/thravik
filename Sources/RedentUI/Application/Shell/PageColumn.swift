import RedentDesign
import SwiftUI

/// The chrome, and the page underneath it.
///
/// Visible navigation reserves a row; edge-revealed navigation overlays the
/// page temporarily without changing a site's layout or scroll position.
struct PageColumn<Backdrop: View>: View {
    @Bindable var model: BrowserModel
    let usesTopStrip: Bool
    let overlaidChromeHeight: CGFloat
    let backdrop: Backdrop
    @Environment(\.settingsServices) private var settingsServices

    var body: some View {
        VStack(spacing: 0) {
            if model.showsNavigationBar { chrome.zIndex(1) } else { windowButtonClearance }
            if showsBarAbovePage { BookmarksBar(model: model).zIndex(1) }
            page
        }
    }

    private var page: some View {
        Group {
            if model.showsSettings, let settingsServices {
                SettingsPage(model: model, services: settingsServices)
            } else {
                ContentArea(model: model)
            }
        }
        .pageCard(isInset: !model.isFocusMode && !model.usesEdgeReveal && !isShowingNewTab) { backdrop }
        .overlay(alignment: .topLeading) {
            if !model.showsNavigationBar, let tab = model.selectedTab {
                ChromeLoadingBar(progress: tab.progress, isLoading: tab.isLoading)
                    .id(tab.id)
            }
        }
        .overlay(alignment: .topTrailing) { copiedLinkToast }
    }

    /// Without the rail there is nothing else holding the window buttons, so the
    /// strip starts clear of them. With it, they sit over the rail and the strip
    /// runs to the seam. `ChromeBar` clears them itself, so its address can be
    /// centered on the full row.
    private var chrome: some View {
        VStack(spacing: 0) {
            if usesTopStrip {
                TopTabStrip(model: model)
                    .padding(.leading, model.isSidebarVisible ? 0 : Metric.windowButtonsWidth)
            }
            ChromeBar(model: model)
            if model.showsBookmarksBar { BookmarksBar(model: model) }
        }
        .background { TitlebarDragRegion() }
    }

    /// Pinned to the page rather than the window, so it sits under whichever
    /// bar is showing and follows the revealed one in and out.
    @ViewBuilder
    private var copiedLinkToast: some View {
        if let notice = model.chrome.copiedLink {
            CopiedLinkToast(chrome: model.chrome, notice: notice)
                .padding(.top, Metric.gutter + overlaidChromeHeight)
                .padding(.trailing, Metric.gutter)
                .animation(.spring(duration: 0.26, bounce: 0), value: overlaidChromeHeight)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    /// The sliver the page owes the window buttons while focus mode has put
    /// the toolbar away.
    @ViewBuilder
    private var windowButtonClearance: some View {
        if !model.isSidebarVisible && !model.usesEdgeReveal {
            WindowControlsClearance(model: model)
        }
    }

    private var isShowingNewTab: Bool { model.selectedTab?.url == nil }

    /// With navigation docked in the visible sidebar there is no toolbar to hang
    /// the bar from, so it takes its own row over the page.
    private var showsBarAbovePage: Bool {
        model.showsBookmarksBar && model.usesSidebarNavigation && !model.usesEdgeReveal
    }
}
