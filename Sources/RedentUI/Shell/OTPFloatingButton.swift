import RedentDesign
import SwiftUI

/// Appears over the page whenever a one-time-code field is on screen, showing
/// the live code for the matching Authenticator account.
///
/// Pressing it types the code into the field. It never submits the form — the
/// last step stays the user's.
struct OTPFloatingButton: View {
    @Bindable var model: BrowserModel
    @State private var didFill = false
    @State private var isHovering = false

    var body: some View {
        if let suggestion = model.otp.primary {
            HStack(spacing: Metric.gutter - 2) {
                countdown(for: suggestion)
                labels(for: suggestion)
                if model.otp.suggestions.count > 1 || model.otp.isUnmatched {
                    OTPAccountPicker(model: model)
                }
            }
            .padding(.leading, Metric.gutter)
            .padding(.trailing, Metric.gutter + 2)
            .padding(.vertical, 9)
            .background { capsule }
            .scaleEffect(isHovering ? 1.035 : 1)
            .contentShape(.capsule)
            .onTapGesture { fill(suggestion) }
            .onHover { hovering in
                withAnimation(.spring(duration: 0.25)) { isHovering = hovering }
            }
            .help("Fill the one-time code for \(suggestion.account.displayName)")
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .task(id: autoFillToken) { await autoFillIfNeeded() }
        }
    }

    private func countdown(for suggestion: OTPCoordinator.Suggestion) -> some View {
        ZStack {
            CountdownRing(
                fraction: suggestion.code.fractionRemaining(at: model.otp.now),
                lineWidth: 2.5
            )
            Text(didFill ? "✓" : "\(suggestion.code.secondsRemaining(at: model.otp.now))")
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.chromeSecondaryText)
                .contentTransition(.numericText())
        }
        .frame(width: 26, height: 26)
    }

    private func labels(for suggestion: OTPCoordinator.Suggestion) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text((model.otp.isUnmatched ? "choose account" : issuerLabel(for: suggestion)).uppercased())
                .font(.system(size: 8.5, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Palette.chromeSecondaryText)
            Text(didFill ? "Filled" : suggestion.code.grouped)
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(Palette.chromeText)
                .contentTransition(.numericText())
        }
    }

    private var capsule: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Palette.accent.opacity(0.30))
                .blur(radius: 14)
                .padding(-3)
            Color.clear.glassCapsuleSurface(tint: Palette.accent)
        }
    }

    private func issuerLabel(for suggestion: OTPCoordinator.Suggestion) -> String {
        let issuer = suggestion.account.issuer
        return issuer.isEmpty ? suggestion.account.accountName : issuer
    }

    private func fill(_ suggestion: OTPCoordinator.Suggestion) {
        guard let tab = model.selectedTab else { return }
        Task {
            await tab.fillOTPCode(suggestion.code.digits)
            model.otp.markFilled(at: tab.url)
            if model.otp.originMatched {
                await model.otp.remember(suggestion)
            }
            withAnimation(.spring(duration: 0.2)) { didFill = true }
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeOut(duration: 0.25)) { didFill = false }
        }
    }

    private var autoFillToken: String? {
        guard model.otp.shouldAutoFill, let suggestion = model.otp.primary else { return nil }
        return "\(suggestion.id.uuidString)|\(suggestion.code.digits)"
    }

    private func autoFillIfNeeded() async {
        guard model.otp.shouldAutoFill, let suggestion = model.otp.primary else { return }
        fill(suggestion)
    }
}
