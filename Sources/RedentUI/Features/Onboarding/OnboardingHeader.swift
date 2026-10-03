import SwiftUI

struct OnboardingHeader: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(model.isDemo ? "THRAVIK · DEMO" : "THRAVIK")
                    .font(.system(size: 10, weight: .semibold)).tracking(2).foregroundStyle(.secondary)
                Spacer()
                soundButton
                if model.isDemo {
                    Button("Exit demo") { model.finish() }.buttonStyle(.plain).font(.caption)
                }
            }
            GeometryReader { geometry in
                Capsule().fill(.white.opacity(0.12))
                    .overlay(alignment: .leading) {
                        Capsule().fill(LinearGradient(colors: [.orange, .pink, .purple],
                                                      startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * CGFloat(model.stepNumber) / CGFloat(OnboardingModel.Step.allCases.count))
                    }
            }
            .frame(height: 3)
            .accessibilityLabel("Setup step \(model.stepNumber) of \(OnboardingModel.Step.allCases.count)")
        }
    }

    private var soundButton: some View {
        Button(action: model.toggleSound) {
            Image(systemName: model.soundEnabled && !model.soundUnavailable ? "speaker.wave.2" : "speaker.slash")
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .disabled(model.soundUnavailable)
        .accessibilityLabel(model.soundEnabled ? "Mute onboarding sound" : "Enable onboarding sound")
        .help(model.soundUnavailable ? "Audio unavailable. Setup still works." : "Quiet ambient audio and transition sounds")
    }
}
