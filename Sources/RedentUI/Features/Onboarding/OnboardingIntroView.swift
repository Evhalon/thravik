import SwiftUI

struct OnboardingIntroView: View {
    @Bindable var model: OnboardingModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var wordIndex = 0
    private let words = ["The internet.", "Less noise.", "More room.", "Yours."]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.025, green: 0.025, blue: 0.03).ignoresSafeArea()
                RadialGradient(colors: [.orange.opacity(0.08), .clear], center: .bottom,
                               startRadius: 0, endRadius: geometry.size.width * 0.65)
                center(fontSize: min(88, max(36, geometry.size.width * 0.075)))
                controls
            }
        }
        .task { await reveal() }
    }

    private func center(fontSize: CGFloat) -> some View {
        VStack(spacing: 36) {
            if isReady { OnboardingPortal().transition(.opacity.combined(with: .scale(scale: 0.9))) }
            Text(words[wordIndex])
                .font(.system(size: fontSize, weight: .medium, design: .rounded))
                .tracking(-2).multilineTextAlignment(.center)
                .id(wordIndex)
                .transition(.opacity.combined(with: .scale(scale: reduceMotion ? 1 : 0.96)))
                .accessibilityAddTraits(.updatesFrequently)
            if isReady {
                Button("Make it yours") { model.advance() }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .transition(.opacity)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.65), value: wordIndex)
    }

    private var controls: some View {
        VStack {
            HStack(spacing: 18) {
                if model.isDemo { Text("DEMO").font(.caption).foregroundStyle(.secondary) }
                Spacer()
                Button(action: model.toggleSound) {
                    Image(systemName: model.soundEnabled && !model.soundUnavailable
                          ? "speaker.wave.2" : "speaker.slash")
                }
                .disabled(model.soundUnavailable)
                .accessibilityLabel(model.soundEnabled ? "Mute onboarding sound" : "Enable onboarding sound")
                if model.isDemo { Button("Exit demo") { model.finish() } }
            }
            Spacer()
            if !isReady { Button("Skip intro") { model.advance() }.foregroundStyle(.secondary) }
        }
        .buttonStyle(.plain).font(.caption).padding(28)
    }

    private var isReady: Bool { wordIndex == words.count - 1 }

    private func reveal() async {
        guard !reduceMotion else { wordIndex = words.count - 1; return }
        for index in 1..<words.count {
            do { try await Task.sleep(for: .seconds(1.8)) }
            catch { return }
            guard !Task.isCancelled else { return }
            wordIndex = index
        }
    }
}
