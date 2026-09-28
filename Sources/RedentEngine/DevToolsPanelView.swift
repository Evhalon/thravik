import SwiftUI
import WebKit

/// A tab's page, with Chrome's DevTools docked in it when open, laid out the
/// way Chrome does: DevTools fills the tab and reports the rectangle it left
/// for the page, and the page sits in that rectangle. Dragging DevTools' own
/// divider, or docking it to another side, moves the rectangle.
///
/// The page is the same view whether DevTools is open or not, and fills the
/// tab until DevTools reports its rectangle. Swapping it for another view
/// re-hosted the web view, and hiding it until DevTools had laid out left the
/// still-blank frontend on show: either way the tab flashed white.
struct DockedDevToolsView: View {
    let tab: WebTab

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let panel = tab.devToolsPanel {
                DevToolsFrontendHost(frontend: panel.frontend)
            }
            WebContentView(tab: tab)
                .frame(width: pageBounds?.width, height: pageBounds?.height)
                .offset(x: pageBounds?.minX ?? 0, y: pageBounds?.minY ?? 0)
        }
    }

    private var pageBounds: CGRect? { tab.devToolsPanel?.pageBounds }
}

/// Hosts the DevTools frontend's web view.
private struct DevToolsFrontendHost: NSViewRepresentable {
    let frontend: WKWebView

    func makeNSView(context: Context) -> WKWebView {
        frontend
    }

    func updateNSView(_ view: WKWebView, context: Context) {}
}
