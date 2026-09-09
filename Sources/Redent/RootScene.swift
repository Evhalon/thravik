import RedentUI
import SwiftUI

/// Creates the app's shared container on first appearance and hands it to the
/// window. Separated from `RedentApp` so the container is built exactly once,
/// not on every re-evaluation of the `App` value — and shared by every window,
/// which is what lets two of them see the same history and the same cookies.
struct RootScene: View {
    @Binding var container: AppContainer?
    let spec: BrowserWindowSpec
    let delegate: AppDelegate

    var body: some View {
        Group {
            if let container {
                BrowserWindowScene(app: container, spec: spec)
            } else {
                Color.clear
            }
        }
        .task {
            guard container == nil else { return }
            let created = AppContainer()
            container = created
            delegate.container = created
        }
    }
}
