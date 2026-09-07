import AppKit
@preconcurrency import AVFoundation
import RedentDesign
import SwiftUI

/// Shown instead of the live preview when the camera hasn't been granted, or
/// has been explicitly denied. Kept calm and factual — no scare language.
struct CameraPermissionView: View {
    let status: AVAuthorizationStatus
    let onRequestAccess: () -> Void

    var body: some View {
        VStack(spacing: Metric.gutter) {
            Image(systemName: "camera")
                .font(.system(size: 32))
                .foregroundStyle(Palette.chromeSecondaryText)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Palette.chromeSecondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            actionButton
        }
        .padding(Metric.gutter * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassPanel(radius: Metric.cornerRadius, tint: nil)
    }

    private var title: String {
        status == .denied || status == .restricted ? "Camera access is off" : "Camera access needed"
    }

    private var message: String {
        switch status {
        case .denied, .restricted:
            "Redent needs the camera to scan the QR code from Google Authenticator's export screen. Turn it on in System Settings."
        default:
            "Redent needs the camera to scan the QR code from Google Authenticator's export screen."
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if status == .denied || status == .restricted {
            Button("Open System Settings", action: openSystemSettings)
                .buttonStyle(.glassProminent)
        } else {
            Button("Allow Camera Access", action: onRequestAccess)
                .buttonStyle(.glassProminent)
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    CameraPermissionView(status: .denied, onRequestAccess: {})
        .frame(width: 420, height: 320)
}
