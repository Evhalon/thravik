import Foundation
import RedentKit

/// Form history in memory, ranked by the real index.
actor FakeFormHistoryStore: FormHistoryStoring {
    private var index = FormHistoryIndex()

    init(_ entries: [FormEntry] = []) {
        index.record(entries, at: Date(timeIntervalSince1970: 0))
    }

    var rows: [FormHistoryRow] { index.rows }

    func record(_ entries: [FormEntry], at date: Date) { index.record(entries, at: date) }

    func suggestions(for key: FormFieldKey, matching prefix: String, limit: Int) -> [String] {
        index.suggestions(for: key, matching: prefix, limit: limit)
    }

    func remove(_ value: String, for key: FormFieldKey) { index.remove(value, for: key) }
    func removeAll() { index = FormHistoryIndex() }
}

/// A tab that remembers what form history told its page.
@MainActor
final class FormRecordingTab: BrowserTab {
    let id = UUID()
    var snapshot = TabSnapshot()
    var title = ""
    var url: URL?
    var progress: Double = 0
    var isLoading = false
    var canGoBack = false
    var canGoForward = false
    var isHibernated = false
    var isPinned = false
    var canFloatVideo = false
    var isVideoFloating = false
    var origin: Origin? { nil }
    var zoom: Double = PageZoom.identity
    private(set) var announcedCounts: [Int] = []
    private(set) var filledValues: [String] = []

    func showFormSuggestions(count: Int) { announcedCounts.append(count) }
    func fillFormField(_ value: String) { filledValues.append(value) }
    func setZoom(_ level: Double) {}
    func load(_ url: URL) {}
    func goBack() {}
    func goForward() {}
    func reload() {}
    func stopLoading() {}
    func fillCredential(username: String, password: String) async {}
    func fillOTPCode(_ code: String) async {}
    func hibernate() {}
    var timeline: [NavigationEntry] { [] }
    func travel(to entry: NavigationEntry) {}
    func forgetTimeline(domain: String) {}
}
