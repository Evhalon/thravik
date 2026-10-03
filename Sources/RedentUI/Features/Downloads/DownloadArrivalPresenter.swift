import RedentKit
import SwiftUI

/// Plays the arrival flight in the key window, and only while its downloads
/// button is on screen. Every window shares one downloads model; a flight in
/// each would be a flurry.
struct DownloadArrivalPresenter: ViewModifier {
    let downloads: DownloadsModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appearsActive) private var appearsActive
    @State private var buttonFrame: CGRect = .zero
    @State private var containerSize: CGSize = .zero
    @State private var flying: DownloadArrivalCue?
    @State private var handledCueID: UUID?

    /// How long a cue waits for the button to lay out before it is dropped.
    private static let layoutGrace: Duration = .milliseconds(80)

    func body(content: Content) -> some View {
        content
            .coordinateSpace(.named(DownloadsButtonFrameKey.space))
            .onPreferenceChange(DownloadsButtonFrameKey.self) { buttonFrame = $0 }
            .onGeometryChange(for: CGSize.self, of: \.size) { containerSize = $0 }
            .overlay { flightLayer }
            .onChange(of: downloads.arrivalCue?.id) { _, _ in considerFlight() }
            .onChange(of: buttonFrame) { _, _ in considerFlight() }
            .task(id: downloads.arrivalCue?.id) { await dropUnplayableCue() }
    }

    @ViewBuilder
    private var flightLayer: some View {
        if let flying {
            DownloadArrivalOverlay(
                cue: flying,
                start: CGPoint(x: containerSize.width / 2, y: min(containerSize.height * 0.2, 140)),
                end: CGPoint(x: buttonFrame.midX, y: buttonFrame.midY),
                reduceMotion: reduceMotion,
                onFinished: finishFlight
            )
            .id(flying.id)
            .allowsHitTesting(false)
        }
    }

    private var buttonIsVisible: Bool {
        guard buttonFrame.width > 8, buttonFrame.height > 8 else { return false }
        let bounds = CGRect(origin: .zero, size: containerSize)
        return bounds.contains(CGPoint(x: buttonFrame.midX, y: buttonFrame.midY))
    }

    private var playableCue: DownloadArrivalCue? {
        guard let cue = downloads.arrivalCue, cue.kind == .flight, cue.id != handledCueID else { return nil }
        return appearsActive && buttonIsVisible ? cue : nil
    }

    private func considerFlight() {
        guard flying == nil, let cue = playableCue else { return }
        handledCueID = cue.id
        flying = cue
    }

    /// A burst that arrives mid-flight plays after the landing.
    private func finishFlight() {
        if !reduceMotion { downloads.noteArrivalLanded() }
        flying = nil
        considerFlight()
    }

    /// A cue the button cannot take within a beat stays quiet, so revealing
    /// the button later never replays an old arrival.
    private func dropUnplayableCue() async {
        guard let id = downloads.arrivalCue?.id else { return }
        try? await Task.sleep(for: Self.layoutGrace)
        guard !Task.isCancelled else { return }
        considerFlight()
        if flying == nil { handledCueID = id }
    }
}
