import SwiftUI
import WebKit

/// SwiftUI host for a tab's web view. Renders nothing heavier than a
/// background for a hibernated tab, and wakes it on appear — this is the
/// only place `RedentUI` touches a tab's web content, and it never sees a
/// WebKit type to do it.
public struct WebContentView: View {
    private let tab: WebTab

    public init(tab: WebTab) {
        self.tab = tab
    }

    public var body: some View {
        Group {
            if tab.isHibernated {
                Color(nsColor: .windowBackgroundColor)
            } else {
                WebKitHostView(webView: tab.webView)
            }
        }
        // minWidth 0 lets the page compress when the sidebar takes space.
        // Without it, WKWebView's document width becomes the floor.
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .onAppear { tab.wakeIfNeeded() }
    }
}

/// Thin `NSViewRepresentable` wrapper — it never constructs or configures a
/// web view itself, only hosts one `WebTab` already built.
///
/// Hosts through a container rather than returning the web view directly:
/// `makeNSView` runs once per view identity, so a tab that wakes up and builds
/// a *new* web view would otherwise keep showing the one it was born with.
private struct WebKitHostView: NSViewRepresentable {
    let webView: WKWebView?

    func makeNSView(context: Context) -> NSView {
        let container = WebViewContainer()
        container.autoresizingMask = [.width, .height]
        container.attach(webView)
        return container
    }

    func updateNSView(_ container: NSView, context: Context) {
        guard let container = container as? WebViewContainer else { return }
        container.attach(webView)
    }

    /// Take the size SwiftUI proposes (the pane next to the sidebar), never
    /// the web view's intrinsic document size.
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSView, context: Context) -> CGSize {
        proposal.replacingUnspecifiedDimensions(by: .zero)
    }
}
