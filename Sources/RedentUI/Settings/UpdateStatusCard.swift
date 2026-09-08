import RedentDesign
import RedentKit
import SwiftUI

/// One line of state and the action that follows from it.
struct UpdateStatusCard: View {
    let updates: UpdateModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: Metric.tightGutter + 2) {
                if updates.isBusy {
                    ProgressView().controlSize(.small)
                }
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(isFailed ? Palette.danger : Palette.chromeText)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            action
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Metric.mediumRadius, style: .continuous)
                .fill(Palette.chromeFill)
        }
    }

    @ViewBuilder
    private var action: some View {
        if case .available(let release) = updates.phase {
            HStack(spacing: Metric.gutter) {
                button("Update and restart") {
                    Task { await updates.installAndRestart(release) }
                }
                if let page = release.pageURL {
                    Link("What's new", destination: page)
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.accent)
                }
            }
        } else if !updates.isBusy {
            button("Check for updates") {
                Task { await updates.check() }
            }
        }
    }

    private func button(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(PressScaleStyle())
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Palette.chromeText)
            .padding(.horizontal, 14)
            .frame(height: 26)
            .background {
                Capsule().fill(Palette.accent.opacity(0.22))
            }
            .disabled(updates.isBusy)
    }

    private var isFailed: Bool {
        if case .failed = updates.phase { return true }
        return false
    }

    private var message: String {
        switch updates.phase {
        case .idle: "Not checked yet."
        case .checking: "Checking for updates…"
        case .upToDate: "Thravik is up to date."
        case .available(let release): "Version \(release.version) is available."
        case .installing: "Downloading and verifying the update…"
        case .restarting: "Restarting into the new version…"
        case .failed(let reason): reason
        }
    }
}
