import RedentDesign
import SwiftUI

struct OnboardingDefaultBrowserPage: View {
    @Bindable var onboarding: OnboardingModel
    @Bindable var defaultBrowser: DefaultBrowserModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "safari")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Palette.accent)
            Text("One last choice.")
                .font(.system(size: 30, weight: .medium, design: .rounded))
            Text("Choose where links open. You can change this any time in macOS settings.")
                .foregroundStyle(Palette.chromeSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
            if onboarding.isDemo { demoNotice }
            if defaultBrowser.isDefault && !onboarding.isDemo { currentStatus }
            defaultChoice
            HStack(spacing: 10) {
                option(title: "Keep current", detail: "Leave your browser choice as it is.",
                       symbol: "arrow.uturn.backward", prominent: false, action: keepCurrent)
                option(title: "Decide later", detail: "Finish setup without changing anything.",
                       symbol: "clock", prominent: false, action: finish)
            }
            if defaultBrowser.isWorking && !onboarding.isDemo {
                ProgressView("Waiting for macOS…").controlSize(.small)
            }
        }
        .task { await refreshStatus() }
    }

    private var demoNotice: some View {
        Label("Demo only. These choices won’t contact macOS or be saved.", systemImage: "sparkles")
            .font(.caption)
            .foregroundStyle(Palette.chromeSecondaryText)
    }

    private var currentStatus: some View {
        Label("Thravik is already your default browser.", systemImage: "checkmark.circle.fill")
            .font(.caption)
            .foregroundStyle(Palette.accent)
    }

    private var defaultChoice: some View {
        option(title: "Use Thravik", detail: "macOS will ask you to confirm. Links will open here.",
               symbol: "arrow.up.forward.app", prominent: true, action: chooseThravik)
    }

    private func option(title: String, detail: String, symbol: String,
                        prominent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.system(size: 17)).frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 13, weight: .semibold))
                    Text(detail).font(.system(size: 11)).foregroundStyle(Palette.chromeSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(prominent ? Color.white : Palette.chromeText)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                    .fill(prominent ? Palette.accent.opacity(0.9) : Palette.chromeFill)
                    .overlay {
                        if !prominent {
                            RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                                .strokeBorder(Palette.hairline, lineWidth: Metric.hairWidth)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
        .disabled(prominent && (defaultBrowser.isWorking || defaultBrowser.isDefault) && !onboarding.isDemo)
    }

    private func chooseThravik() {
        onboarding.finishDefaultBrowserChoice(.useThravik, using: defaultBrowser)
    }

    private func keepCurrent() {
        onboarding.finishDefaultBrowserChoice(.keepCurrent, using: defaultBrowser)
    }

    private func finish() {
        onboarding.finishDefaultBrowserChoice(.decideLater, using: defaultBrowser)
    }

    private func refreshStatus() async {
        guard !onboarding.isDemo else { return }
        await defaultBrowser.refreshStatus()
    }
}
