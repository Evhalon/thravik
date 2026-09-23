import RedentDesign
import SwiftUI

/// Appears on a site's two-factor setup page. One press reads the QR code the
/// page shows and keeps it in the vault — no phone, no second app — and the
/// one-time-code button takes over from there.
struct TwoFactorSetupButton: View {
    @Bindable var model: BrowserModel

    var body: some View {
        if model.twoFactor.isVisible {
            HStack(spacing: Metric.gutter - 2) {
                icon.frame(width: 26, height: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text(caption.uppercased()).font(.system(size: 8.5, weight: .bold)).tracking(0.8)
                        .foregroundStyle(Palette.chromeSecondaryText)
                    Text(title).font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Palette.chromeText)
                }
            }
            .padding(.horizontal, Metric.gutter)
            .padding(.vertical, 9)
            .background { Color.clear.glassCapsuleSurface(tint: Palette.accent) }
            .contentShape(.capsule)
            .onTapGesture(perform: act)
            .help("Save this site's two-factor code to Redent")
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .task(id: model.twoFactor.phase) { await hideConfirmationLater() }
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch model.twoFactor.phase {
        case .reading: ProgressView().controlSize(.small)
        case .saved: Image(systemName: "checkmark.seal.fill").foregroundStyle(Palette.accent)
        default: Image(systemName: "qrcode.viewfinder").foregroundStyle(Palette.accent)
        }
    }

    private var caption: String {
        switch model.twoFactor.phase {
        case .saved(let name): name
        case .notFound: "no code found"
        default: "two-factor setup"
        }
    }

    private var title: String {
        switch model.twoFactor.phase {
        case .reading: "Reading the code…"
        case .saved: "Saved — codes fill from now on"
        case .notFound: "Scroll the QR code into view and try again"
        default: "Save to Redent instead of your phone"
        }
    }

    private func act() {
        switch model.twoFactor.phase {
        case .offered, .notFound: model.saveTwoFactorSetup()
        case .saved: model.twoFactor.dismiss()
        default: break
        }
    }

    private func hideConfirmationLater() async {
        guard case .saved = model.twoFactor.phase else { return }
        try? await Task.sleep(for: .seconds(4))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.25)) { model.twoFactor.dismiss() }
    }
}
