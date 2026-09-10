import RedentDesign
import RedentKit
import SwiftUI

/// One pane's page. Clicking a pane makes it the active one, which is what the
/// toolbar, autofill and one-time codes then act on.
struct PagePane: View {
    @Bindable var model: BrowserModel
    let tab: (any BrowserTab)?
    let pane: SplitLayout.Pane

    var body: some View {
        content
            .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.canvas)
            .overlay(alignment: .top) { activeEdge }
            .contentShape(.rect)
            .onTapGesture { focusIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        // A tab with no URL is a new tab: it shows Redent's own page rather
        // than an empty web view, and never touches the network.
        if let tab, tab.pageTrustIssue == .invalidCertificate, let url = tab.url {
            CertificateWarningPage(url: url, retry: { tab.load(url) }) {
                tab.proceedThroughInvalidCertificate()
            }
        } else if let tab, tab.url != nil {
            model.content(tab.id).id(tab.id)
        } else if pane == .primary {
            NewTabPage(model: model)
                .id(tab?.id)
        } else {
            Color.clear
        }
    }

    /// A no-op tap still mutates `split` and SwiftUI rebuilds the page card,
    /// which is enough to send a live video layer black.
    private func focusIfNeeded() {
        guard model.split.isSplit, model.split.activePane != pane else { return }
        model.split.focus(pane)
    }

    /// Only drawn while the window is actually split: with one pane there is
    /// nothing to distinguish it from.
    @ViewBuilder
    private var activeEdge: some View {
        if model.split.isSplit && model.split.activePane == pane {
            Rectangle()
                .fill(Palette.accent)
                .frame(height: 2)
                .transition(.opacity)
        }
    }
}
