import RedentDesign
import SwiftUI

/// Explains why an internal site's certificate could not be verified.
struct CertificateWarningPage: View {
    let url: URL
    let retry: () -> Void
    let proceed: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.trianglebadge.exclamationmark")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(Palette.danger)
            Text("Your connection is not private")
                .font(.title2.weight(.semibold))
            Text("Redent could not verify the certificate presented by \(host). The page was not opened.")
                .multilineTextAlignment(.center)
            Text("Only proceed if you trust this site. Redent will remember this choice for this exact site.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack {
                Button("Try Again", action: retry)
                Button("Proceed Anyway", role: .destructive, action: proceed)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: 460)
        .padding(32)
    }

    private var host: String { url.host ?? "this site" }
}
