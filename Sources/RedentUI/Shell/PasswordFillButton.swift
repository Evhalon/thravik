import RedentDesign
import RedentKit
import SwiftUI

/// Offers saved logins on a detected login page. Tap fills; never submits.
struct PasswordFillButton: View {
    @Bindable var model: BrowserModel
    @State private var isHovering = false

    var body: some View {
        if model.autofill.shouldOfferFill, let credential = model.autofill.suggestions.first {
            HStack(spacing: Metric.gutter - 2) {
                Image(systemName: "key.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Palette.accent.opacity(0.16)))
                labels(for: credential)
                if model.autofill.suggestions.count > 1 {
                    PasswordFillPicker(model: model, fill: fill)
                }
            }
            .padding(.leading, Metric.gutter)
            .padding(.trailing, Metric.gutter + 2)
            .padding(.vertical, 9)
            .background { capsule }
            .scaleEffect(isHovering ? 1.035 : 1)
            .contentShape(.capsule)
            .onTapGesture { fill(credential) }
            .onHover { hovering in
                withAnimation(.spring(duration: 0.25)) { isHovering = hovering }
            }
            .help("Fill the saved login for \(label(for: credential))")
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func labels(for credential: Credential) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("fill password").font(.system(size: 8.5, weight: .bold)).tracking(0.8)
                .foregroundStyle(Palette.chromeSecondaryText)
            Text(label(for: credential))
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(Palette.chromeText)
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

    private func label(for credential: Credential) -> String {
        credential.username.isEmpty ? credential.origin.displayHost : credential.username
    }

    private func fill(_ credential: Credential) {
        guard let tab = model.selectedTab else { return }
        Task {
            await tab.fillCredential(username: credential.username, password: credential.password)
            await model.autofill.credentialFilled(credential)
        }
    }
}
