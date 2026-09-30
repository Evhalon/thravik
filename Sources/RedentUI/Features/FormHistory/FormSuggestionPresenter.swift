import AppKit
import SwiftUI

/// Puts the form-history panel on screen while there is a menu to show, and
/// takes it down when the window stops being the one the user works in.
struct FormSuggestionPresenter: NSViewRepresentable {
    let model: BrowserModel
    let menu: FormSuggestionMenu?

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeNSView(context: Context) -> NSView { NSView(frame: .zero) }

    func updateNSView(_ view: NSView, context: Context) {
        context.coordinator.present(menu, in: view.window)
    }

    static func dismantleNSView(_ view: NSView, coordinator: Coordinator) {
        coordinator.stop()
    }

    @MainActor
    final class Coordinator {
        let panel = FormSuggestionPanel()
        private let model: BrowserModel
        private var resignObserver: NSObjectProtocol?

        init(model: BrowserModel) { self.model = model }

        func present(_ menu: FormSuggestionMenu?, in window: NSWindow?) {
            guard let menu, let window, window.isKeyWindow else {
                panel.hide()
                return
            }
            observeResign(of: window)
            panel.show(rows: menu.items.count, under: menu.anchor, in: window) {
                FirstMouseHostingView(rootView: FormSuggestionList(model: model))
            }
        }

        func stop() {
            panel.hide()
            if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
            resignObserver = nil
        }

        private func observeResign(of window: NSWindow) {
            guard resignObserver == nil else { return }
            resignObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification, object: window, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.model.dismissFormSuggestions() }
            }
        }
    }
}
