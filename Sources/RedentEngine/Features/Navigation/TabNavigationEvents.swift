import Foundation
import RedentKit

@MainActor
final class TabNavigationEvents {
    private var navigationID = UUID()
    private var recordedURL: URL?
    private var didFinish = false

    func started() {
        navigationID = UUID()
        recordedURL = nil
        didFinish = false
    }

    func finished(_ tab: WebTab) {
        didFinish = true
        emit(tab)
    }

    func locationChanged(_ tab: WebTab) {
        guard didFinish, !tab.isLoading, tab.url != recordedURL else { return }
        navigationID = UUID()
        emit(tab)
    }

    private func emit(_ tab: WebTab) {
        guard let url = tab.url, ["https", "http"].contains(url.scheme?.lowercased() ?? "") else { return }
        recordedURL = url
        tab.controller?.onNavigation?(tab.snapshot, navigationID)
        tab.controller?.onChange?()
    }
}
