import RedentDesign
import RedentKit
import SwiftUI

/// The file icon that travels the arrival arc, then disappears.
struct DownloadArrivalOverlay: View {
    let cue: DownloadArrivalCue
    let start: CGPoint
    let end: CGPoint
    let reduceMotion: Bool
    let onFinished: () -> Void

    @State private var progress = 0.0
    @State private var opacity = 1.0

    var body: some View {
        icon
            .modifier(ArcMotion(progress: reduceMotion ? 1 : progress, start: start, end: end))
            .opacity(opacity)
            .allowsHitTesting(false)
            .onAppear(perform: play)
            .task { await finishAfterDelay() }
    }

    private var icon: some View {
        DownloadFileIcon(filename: cue.filename, size: 34)
            .shadow(color: .black.opacity(0.28), radius: 8, y: 3)
            .overlay(alignment: .topTrailing) { countBadge }
    }

    @ViewBuilder
    private var countBadge: some View {
        if cue.count > 1 {
            Text("\(cue.count)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(minWidth: 16, minHeight: 16)
                .background(Circle().fill(Palette.accent))
                .offset(x: 6, y: -6)
        }
    }

    private func play() {
        if reduceMotion {
            opacity = 0
            withAnimation(.easeOut(duration: 0.14)) { opacity = 1 }
            return
        }
        withAnimation(.timingCurve(0.2, 0.75, 0.25, 1, duration: DownloadArrivalPath.duration)) {
            progress = 1
        }
    }

    private func finishAfterDelay() async {
        if reduceMotion {
            try? await Task.sleep(for: .seconds(0.16))
            withAnimation(.easeIn(duration: 0.12)) { opacity = 0 }
            try? await Task.sleep(for: .seconds(0.12))
        } else {
            try? await Task.sleep(for: .seconds(DownloadArrivalPath.duration))
        }
        guard !Task.isCancelled else { return }
        onFinished()
    }
}

/// Interpolates `progress`, not the resulting point: animating `.position`
/// directly would cut a straight line instead of the arc.
private struct ArcMotion: ViewModifier, Animatable {
    var progress: Double
    let start: CGPoint
    let end: CGPoint

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(DownloadArrivalPath.scale(progress: progress))
            .position(DownloadArrivalPath.point(progress: progress, from: start, to: end))
    }
}
