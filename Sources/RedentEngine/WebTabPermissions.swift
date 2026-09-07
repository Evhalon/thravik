import RedentKit
import WebKit

/// Media-capture requests. WebKit asks per security origin; Redent answers from
/// the user's stored decision, and falls back to prompting rather than to a
/// silent grant whenever there is no decision to apply.
extension WebTabNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType
    ) async -> WKPermissionDecision {
        let site = Origin(scheme: origin.protocol, host: origin.host)
        let decisions = Self.permissions(for: type).compactMap { permissionDecision(for: site, $0) }
        guard decisions.count == Self.permissions(for: type).count, !decisions.isEmpty else {
            return .prompt
        }
        if decisions.contains(.deny) { return .deny }
        return decisions.allSatisfy { $0 == .allow } ? .grant : .prompt
    }

    private static func permissions(for type: WKMediaCaptureType) -> [SitePermission] {
        switch type {
        case .camera: [.camera]
        case .microphone: [.microphone]
        case .cameraAndMicrophone: [.camera, .microphone]
        @unknown default: []
        }
    }
}
