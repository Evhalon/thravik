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
        WindowGroup(for: BrowserWindowSpec.self) { $spec in
            RootScene(container: $container, spec: spec, delegate: delegate)
                .frame(minWidth: 760, minHeight: 480)
                .ignoresSafeArea(.container, edges: .top)
        } defaultValue: {
            .primary
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 840)
        // A secondary window's identity is a fresh UUID with no saved workspace
        // behind it, so restoring one at launch would reopen an empty shell.
        .restorationBehavior(.disabled)
        .commands {
            BrowserCommands()
            QuitCommand(container: container)
        }
    }
}
