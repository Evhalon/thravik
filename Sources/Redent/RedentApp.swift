import RedentUI
import SwiftUI

@main
struct RedentApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    // Built once, lazily: `@State private var container = AppContainer()` would
    // construct a throwaway container — stores, tab controller, and an initial
    // web view — on every re-evaluation of this struct, and discard it.
    @State private var container: AppContainer?

    var body: some Scene {
        WindowGroup {
            RootScene(container: $container, delegate: delegate)
                .frame(minWidth: 760, minHeight: 480)
                .ignoresSafeArea(.container, edges: .top)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 840)
        .commands {
            if let container { BrowserCommands(model: container.model) }
        }
    }
}
