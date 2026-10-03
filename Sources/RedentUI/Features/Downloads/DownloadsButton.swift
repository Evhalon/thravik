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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulses = 0

    private static let autoCloseDelay: Duration = .seconds(4)
    private static let completionFlash: Duration = .seconds(1.6)

    private var downloads: DownloadsModel { model.downloads }

    var body: some View {
        ZStack {
            if !downloads.isEmpty {
                button.transition(.scale(scale: 0.3).combined(with: .opacity))
            }
        }
        .keyframeAnimator(initialValue: 1.0, trigger: pulses) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            SpringKeyframe(1.16, duration: 0.14, spring: .bouncy)
            SpringKeyframe(1.0, duration: 0.3, spring: .smooth)
        }
        .animation(.spring(duration: 0.4, bounce: 0.35), value: downloads.isEmpty)
        .onChange(of: downloads.arrivals) { announceArrival() }
        .onChange(of: downloads.landingPulses) { if appearsActive { pulse() } }
        .onChange(of: downloads.completions) {
            completionToken += 1
            pulse()
        }
        .task(id: autoCloseToken) { await autoClose() }
        .task(id: completionToken) { await flashCompletion() }
    }

    private var frameAnchor: some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: DownloadsButtonFrameKey.self,
                value: geometry.frame(in: .named(DownloadsButtonFrameKey.space))
            )
        }
    }

    private var button: some View {
        Button(action: toggleList) {
            DownloadsGlyph(
                activeFraction: downloads.activeFraction,
                isActive: !downloads.activeItems.isEmpty,
                showsCompletion: showsCompletion,
                hasUnseenCompletion: downloads.hasUnseenCompletion,
                bounceToken: downloads.arrivals + downloads.landingPulses
            )
        }
        .buttonStyle(PressScaleStyle())
        .help(helpText)
        .accessibilityLabel(helpText)
        .popover(isPresented: $isShowingList, arrowEdge: .bottom) {
            DownloadsPopover(downloads: downloads, onShowAll: showAll)
                .onHover { isHoveringList = $0 }
        }
        .background { frameAnchor }
    }

    private func toggleList() {
        autoCloseToken = 0
        isShowingList.toggle()
    }

    private func showAll() {
        isShowingList = false
        model.sheet = .downloads
    }

    private func pulse() {
        guard !reduceMotion else { return }
        pulses += 1
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
