@preconcurrency import AVFoundation
import RedentDesign
import SwiftUI

/// The camera route: live preview inside a rounded, glass-framed rectangle,
/// gated on permission. Owns the `CameraSession` lifecycle — started on
/// appear, always torn down on disappear (a camera left running is a bug).
struct CameraScanRouteView: View {
    let collector: ScannedPayloadCollector

    @State private var session = CameraSession()
    @State private var status = CameraSession.authorizationStatus

    var body: some View {
        Group {
            if status == .authorized {
                framedPreview
            } else {
                CameraPermissionView(status: status, onRequestAccess: requestAccess)
            }
        }
        .task(id: status) {
            if status == .authorized { await startScanning() }
        }
        .onDisappear { session.stop() }
    }

    private var framedPreview: some View {
        QRCameraView(session: session)
            .clipShape(RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Metric.cornerRadius, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            )
    }

    private func requestAccess() {
        Task {
            _ = await CameraSession.requestAccess()
            status = CameraSession.authorizationStatus
        }
    }

    private func startScanning() async {
        try? await session.start { payload in
            Task { @MainActor in await collector.add(payloadText: payload) }
        }
    }
}
