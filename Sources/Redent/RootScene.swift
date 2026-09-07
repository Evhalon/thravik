import RedentUI
import SwiftUI

/// Creates the app's single container on first appearance and hands it to the
/// window. Separated from `RedentApp` so the container is built exactly once,
/// not on every re-evaluation of the `App` value.
struct RootScene: View {
    @Binding var container: AppContainer?
    let delegate: AppDelegate

    var body: some View {
        Group {
            if let container {
                BrowserWindowView(model: container.model) { route in
                    SheetRouter(route: route, container: container)
                }
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
