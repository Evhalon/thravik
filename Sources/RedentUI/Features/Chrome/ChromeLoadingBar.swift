import RedentDesign
import SwiftUI

struct ChromeLoadingBar: View {
    let progress: Double
    let isLoading: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedProgress = 0.04
    @State private var opacity = 0.0

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(LinearGradient(
                    colors: [Palette.accent.opacity(0.55), Palette.accent, .white.opacity(0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(width: geometry.size.width * displayedProgress, height: 2)
                .shadow(color: Palette.accent.opacity(0.45), radius: 4, y: -1)
        }
        .frame(height: 2)
        .opacity(opacity)
        .accessibilityLabel("Page loading")
        .accessibilityHidden(opacity == 0)
        .onChange(of: progress) { _, _ in advance() }
        .task(id: isLoading) { await updateLoadingState() }
    }

    private func advance() {
        guard isLoading else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.5)) {
            displayedProgress = max(displayedProgress, min(progress, 0.96))
        }
    }

    private func updateLoadingState() async {
        if isLoading {
            displayedProgress = max(0.04, min(progress, 0.96))
            withAnimation(reduceMotion ? nil : .easeIn(duration: 0.18)) { opacity = 1 }
            return
        }
        guard opacity > 0 else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.45)) { displayedProgress = 1 }
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 550))
        guard !Task.isCancelled else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.75)) { opacity = 0 }
    }
}
