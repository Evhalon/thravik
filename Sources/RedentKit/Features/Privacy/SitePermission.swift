import Foundation

/// A capability a page can ask the browser for.
///
/// Only what WebKit actually lets Redent decide is listed here. Safari's wider
/// permission surface is not available through public API, so nothing is
/// enumerated that the browser could not honestly enforce.
public enum SitePermission: String, Codable, Sendable, Hashable, CaseIterable {
    case camera
    case microphone

    public var label: String {
        switch self {
        case .camera: "Camera"
        case .microphone: "Microphone"
        }
    }
}

public enum PermissionDecision: String, Codable, Sendable, Hashable, CaseIterable {
    case ask
    case allow
    case deny

    public var label: String {
        switch self {
        case .ask: "Ask"
        case .allow: "Allow"
        case .deny: "Block"
        }
    }
}
