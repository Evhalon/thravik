import RedentDesign
import SwiftUI

/// The "save this password?" prompt. Deliberately a passive bar rather than a
/// modal — it must never stand between the user and the page they just logged into.
struct PasswordSaveBar: View {
    @Bindable var model: BrowserModel

    var body: some View {
        if let request = model.autofill.pendingSave {
            HStack(spacing: Metric.gutter) {
                Image(systemName: "key.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Palette.accent.opacity(0.16)))

                VStack(alignment: .leading, spacing: 1) {
                    Text(title(for: request.kind))
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Palette.chromeText)
                    Text("\(request.candidate.username) · \(request.candidate.origin.displayHost)")
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.chromeSecondaryText)
                }

                Spacer(minLength: Metric.gutter)

                Button("Not Now") { model.autofill.dismissPendingSave() }
                    .buttonStyle(.borderless)
                    .foregroundStyle(Palette.chromeSecondaryText)
                Button(request.kind == .new ? "Save" : "Update") {
                    Task { await model.autofill.confirmPendingSave() }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.leading, Metric.gutter)
            .padding(.trailing, Metric.gutter)
            .padding(.vertical, 9)
            .floatingGlass(in: RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
            .frame(maxWidth: 470)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func title(for kind: CredentialSaveRequest.Kind) -> String {
        switch kind {
        case .new: "Save this password in Thravik?"
        case .updatedPassword: "Update the saved password?"
        }
    }
}
