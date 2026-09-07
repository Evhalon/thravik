import AppKit
@preconcurrency import AVFoundation
import SwiftUI

/// Hosts `CameraSession`'s preview layer inside a plain `NSView`, sized to
/// track the view's bounds.
struct QRCameraView: NSViewRepresentable {
    let session: CameraSession

    func makeNSView(context: Context) -> PreviewHostView {
        let view = PreviewHostView()
        let layer = session.previewLayer
        layer.videoGravity = .resizeAspectFill
        view.wantsLayer = true
        view.layer?.addSublayer(layer)
        view.previewLayer = layer
        return view
    }

    func updateNSView(_ nsView: PreviewHostView, context: Context) {
        nsView.previewLayer?.frame = nsView.bounds
    }
}

/// A layer-backed view whose only job is to keep the preview layer's frame in
/// sync as the sheet resizes.
final class PreviewHostView: NSView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override func layout() {
        super.layout()
        previewLayer?.frame = bounds
    }
}
