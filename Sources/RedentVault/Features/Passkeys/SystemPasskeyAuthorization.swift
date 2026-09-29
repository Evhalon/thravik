import AuthenticationServices
import RedentKit
import Security

/// WebKit performs the ceremonies; this adapter only grants the browser access.
public actor SystemPasskeyAuthorization: PasskeyAuthorizing {
    private let manager = ASAuthorizationWebBrowserPublicKeyCredentialManager()

    public init() {}

    public func currentAccess() -> BrowserPasskeyAccess {
        guard Self.hasBrowserEntitlement else { return .unavailable }
        return Self.access(for: manager.authorizationStateForPlatformCredentials)
    }

    public func requestAccess() async -> BrowserPasskeyAccess {
        let access = currentAccess()
        guard access == .notDetermined else { return access }
        return Self.access(for: await manager.requestAuthorizationForPublicKeyCredentials())
    }

    static func access(
        for state: ASAuthorizationWebBrowserPublicKeyCredentialManager.AuthorizationState
    ) -> BrowserPasskeyAccess {
        switch state {
        case .authorized: .authorized
        case .denied: .denied
        case .notDetermined: .notDetermined
        @unknown default: .unavailable
        }
    }

    private static var hasBrowserEntitlement: Bool {
        guard let task = SecTaskCreateFromSelf(nil) else { return false }
        let entitlement = "com.apple.developer.web-browser.public-key-credential" as CFString
        return SecTaskCopyValueForEntitlement(task, entitlement, nil) as? Bool == true
    }
}
