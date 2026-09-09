import RedentUI
import SwiftUI

/// Binds one window's scene to the container that serves it.
///
/// Separated from `RootScene` so the container lookup can happen outside a
/// `ViewBuilder`, and so the only place that knows how to open another window —
/// this view's environment action — is also the only place that hands the
/// window model a way to ask for one.
struct BrowserWindowScene: View {
    let app: AppContainer
    let spec: BrowserWindowSpec

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let window = app.window(for: spec)
        return BrowserWindowView(model: window.model) { route in
            SheetRouter(route: route, app: app, window: window)
        }
        .onAppear { window.model.windowOpener = open(isPrivate:) }
        .onDisappear { app.releaseWindow(spec) }
    }

    private func open(isPrivate: Bool) {
        openWindow(value: BrowserWindowSpec(isPrivate: isPrivate))
    }
}
