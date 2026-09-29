import RedentDesign
import SwiftUI

/// The downloads control in the toolbar. It is not there at all until
/// something has been fetched — chrome that does nothing is chrome in the way.
///
/// A new download pops the list open in the window the user is looking at, so
/// they see it start; the list closes itself again unless the pointer is in it.
struct DownloadsButton: View {
    @Bindable var model: BrowserModel
    @State private var isShowingList = false
    @State private var isHoveringList = false
    @State private var showsCompletion = false
    /// Nonzero while an auto-opened list is waiting to close itself.
    @State private var autoCloseToken = 0
    @State private var completionToken = 0
    @Environment(\.appearsActive) private var appearsActive

    private static let autoCloseDelay: Duration = .seconds(4)
    private static let completionFlash: Duration = .seconds(1.6)

    private var downloads: DownloadsModel { model.downloads }

    var body: some View {
        ZStack {
            if !downloads.isEmpty {
                button.transition(.scale(scale: 0.3).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4, bounce: 0.35), value: downloads.isEmpty)
        .onChange(of: downloads.arrivals) { announceArrival() }
        .onChange(of: downloads.completions) { completionToken += 1 }
        .task(id: autoCloseToken) { await autoClose() }
        .task(id: completionToken) { await flashCompletion() }
    }

    private var button: some View {
        Button(action: toggleList) {
            DownloadsGlyph(
                activeFraction: downloads.activeFraction,
                isActive: !downloads.activeItems.isEmpty,
                showsCompletion: showsCompletion,
                hasUnseenCompletion: downloads.hasUnseenCompletion,
                arrivals: downloads.arrivals
            )
        }
        .buttonStyle(PressScaleStyle())
        .help(helpText)
        .accessibilityLabel(helpText)
        .popover(isPresented: $isShowingList, arrowEdge: .bottom) {
            DownloadsPopover(downloads: downloads, onShowAll: showAll)
                .onHover { isHoveringList = $0 }
        }
    }

    private func toggleList() {
        autoCloseToken = 0
        isShowingList.toggle()
    }

    private func showAll() {
        isShowingList = false
        model.sheet = .downloads
    }

    /// Only the key window opens its list: every window shares one download
    /// model, and a popover in each would be a flurry.
    private func announceArrival() {
        guard appearsActive, !isShowingList else { return }
        isShowingList = true
        autoCloseToken += 1
    }

    private func autoClose() async {
        guard autoCloseToken > 0 else { return }
        try? await Task.sleep(for: Self.autoCloseDelay)
        guard !Task.isCancelled, !isHoveringList else { return }
        isShowingList = false
    }

    private func flashCompletion() async {
        guard completionToken > 0 else { return }
        showsCompletion = true
        try? await Task.sleep(for: Self.completionFlash)
        guard !Task.isCancelled else { return }
        showsCompletion = false
    }

    private var helpText: String {
        let active = downloads.activeItems.count
        return active > 0 ? "\(active) downloading" : "Downloads"
    }
}
