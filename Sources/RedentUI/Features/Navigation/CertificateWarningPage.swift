import RedentDesign
import SwiftUI

/// Explains why an internal site's certificate could not be verified.
struct CertificateWarningPage: View {
    let url: URL
    let dismiss: () -> Void
    let proceed: () -> Void

    @State private var showsDetails = false

    var body: some View {
        ZStack { warningCard }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.canvas)
    }

    private var warningCard: some View {
        VStack(alignment: .leading, spacing: Metric.gutter) {
            heading
            Text("The site may be impersonating \(host), which could expose information you enter there.")
                .foregroundStyle(Palette.chromeSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
            if showsDetails { detail }
            actions
        }
        .padding(28)
        .frame(maxWidth: 540, alignment: .leading)
        .floatingGlass(in: RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
    }

    private var heading: some View {
        HStack(spacing: Metric.gutter) {
            Image(systemName: "lock.trianglebadge.exclamationmark")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(Palette.danger)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Palette.danger.opacity(0.14)))
            Text("Connection isn't private")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Palette.chromeText)
        }
    }

    private var detail: some View {
        Text("Thravik could not verify this site's certificate. Continue only if you trust \(host). Your decision applies only to this exact site.")
            .font(.callout)
            .foregroundStyle(Palette.chromeSecondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var actions: some View {
        HStack(spacing: Metric.tightGutter) {
            Button(showsDetails ? "Hide Details" : "Show Details") { showsDetails.toggle() }
                .buttonStyle(.bordered)
            Spacer(minLength: Metric.gutter)
            Button("Close Tab", action: dismiss)
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
            Button("Continue", role: .destructive, action: proceed)
                .buttonStyle(.borderedProminent)
        }
    }

    private var host: String { url.host ?? "this site" }
}
