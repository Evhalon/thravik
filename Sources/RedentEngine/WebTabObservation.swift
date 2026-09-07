import RedentKit
import SwiftUI
import WebKit

/// Mirrors WebKit's KVO-published state into `@Observable` properties.
/// No polling timer: WebKit already publishes every one of these keys.
extension WebTab {
    func setupObservers(on webView: WKWebView) {
        observationTokens = [
            webView.observe(\.title, options: [.new]) { [weak self] view, _ in
                Task { @MainActor in self?.applyTitle(view.title) }
            },
            webView.observe(\.url, options: [.new]) { [weak self] view, _ in
                Task { @MainActor in self?.applyURL(view.url) }
            },
            webView.observe(\.estimatedProgress, options: [.new]) { [weak self] view, _ in
                Task { @MainActor in self?.progress = view.estimatedProgress }
            },
            webView.observe(\.isLoading, options: [.new]) { [weak self] view, _ in
                Task { @MainActor in self?.isLoading = view.isLoading }
            },
            webView.observe(\.canGoBack, options: [.new]) { [weak self] view, _ in
                Task { @MainActor in self?.canGoBack = view.canGoBack }
            },
            webView.observe(\.canGoForward, options: [.new]) { [weak self] view, _ in
                Task { @MainActor in self?.canGoForward = view.canGoForward }
            },
            webView.observe(\.themeColor, options: [.new]) { [weak self] view, _ in
                Task { @MainActor in self?.applyThemeColor(view.themeColor) }
            }
        ]
    }

    func teardownObservers() {
        observationTokens.forEach { $0.invalidate() }
        observationTokens.removeAll()
    }

    private func applyTitle(_ title: String?) {
        guard let title, !title.isEmpty else { return }
        self.title = title
        snapshot.title = title
        timelineRecorder.titleChanged(title, on: self)
    }

    /// A URL change with no load behind it is a same-document move — a router
    /// or an anchor — which never reaches the navigation delegate.
    private func applyURL(_ url: URL?) {
        self.url = url
        self.origin = url.flatMap(Origin.init(url:))
        snapshot.url = url
        if !isLoading, let webView { timelineRecorder.movedWithinDocument(self, webView: webView) }
        navigationEvents.locationChanged(self)
    }

    private func applyThemeColor(_ color: NSColor?) {
        themeColor = color.map { Color(nsColor: $0) }
    }
}
