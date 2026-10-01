import SwiftUI

/// A thin spectrum line along the top of a page while it loads.
///
/// It shows the moment a load starts rather than waiting for WebKit's first
/// progress report, so a reload is visibly under way while the old page is
/// still on screen. It finishes by running to the far edge before fading, so
/// a fast load still reads as done rather than abandoned.
public struct LoadingLine: View {
    private let isLoading: Bool
    private let progress: Double
    @State private var shownFraction: Double = 0
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A load that has barely started still earns a visible stub.
    private static let startingFraction = 0.12

    public init(isLoading: Bool, progress: Double) {
        self.isLoading = isLoading
        self.progress = min(max(progress, 0), 1)
    }

    public var body: some View {
        ZStack {
            if isVisible {
                GeometryReader { proxy in
                    line
                        .frame(width: proxy.size.width * shownFraction, height: Self.thickness)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .transition(.opacity)
            }
        }
        .frame(height: Self.thickness)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: progress) { _, newValue in advance(to: newValue) }
        .task(id: isLoading) { await follow(isLoading) }
    }

    /// An opaque, saturated spectrum: a pale or translucent line vanishes on
    /// white pages, so the colour itself carries the contrast and the glow
    /// lifts it off dark ones.
    private var line: some View {
        Capsule()
            .fill(LinearGradient(colors: Self.spectrum, startPoint: .leading, endPoint: .trailing))
            .overlay { specular }
            .overlay { if !reduceMotion { Shimmer() } }
            .clipShape(.capsule)
            .shadow(color: Self.spectrum[1].opacity(0.55), radius: 5)
    }

    private var specular: some View {
        LinearGradient(colors: [.white.opacity(0.25), .clear],
                       startPoint: .top, endPoint: .bottom)
    }

    private func advance(to fraction: Double) {
        guard isLoading, fraction > shownFraction else { return }
        withAnimation(.easeOut(duration: 0.35)) { shownFraction = fraction }
    }

    private func follow(_ loading: Bool) async {
        if loading {
            shownFraction = 0
            isVisible = true
            withAnimation(.easeOut(duration: 0.3)) {
                shownFraction = max(Self.startingFraction, progress)
            }
            return
        }
        guard isVisible else { return }
        withAnimation(.easeOut(duration: 0.2)) { shownFraction = 1 }
        try? await Task.sleep(for: .milliseconds(260))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.3)) { isVisible = false }
    }

    private static let thickness: CGFloat = 3

    private static let spectrum: [Color] = [
        Color(red: 0.00, green: 0.55, blue: 1.00),
        Color(red: 0.20, green: 0.38, blue: 1.00),
        Color(red: 0.48, green: 0.30, blue: 0.98),
        Color(red: 0.74, green: 0.32, blue: 0.95)
    ]
}

/// A soft highlight sweeping left to right, so a load WebKit has stopped
/// reporting on still looks alive. Its own view so the endless animation
/// exists only while the line is on screen.
private struct Shimmer: View {
    @State private var phase: CGFloat = -0.4

    var body: some View {
        GeometryReader { proxy in
            LinearGradient(colors: [.clear, .white.opacity(0.35), .clear],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: max(proxy.size.width * 0.35, 40))
                .offset(x: phase * proxy.size.width)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) { phase = 1.2 }
        }
    }
}

#Preview("LoadingLine") {
    VStack(spacing: 20) {
        LoadingLine(isLoading: true, progress: 0.1)
        LoadingLine(isLoading: true, progress: 0.6)
    }
    .padding(28)
    .frame(width: 400)
}
