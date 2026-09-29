import Observation
import RedentKit

@MainActor @Observable
public final class PasskeyAccessModel {
    public private(set) var access: BrowserPasskeyAccess?
    public private(set) var isWorking = false
    private let authorizer: any PasskeyAuthorizing

    public init(authorizer: any PasskeyAuthorizing) {
        self.authorizer = authorizer
    }

    public func refresh() async {
        guard !isWorking else { return }
        isWorking = true
        access = await authorizer.currentAccess()
        isWorking = false
    }

    public func requestAccess() async {
        guard !isWorking else { return }
        isWorking = true
        let current = await authorizer.currentAccess()
        access = current == .notDetermined ? await authorizer.requestAccess() : current
        isWorking = false
    }

    var caption: String {
        switch access {
        case nil: "Checking passkey access…"
        case .unavailable:
            "This build cannot use saved passkeys. Install a build with Apple's browser passkey approval."
        case .notDetermined:
            "Allow access to use your saved passkeys on websites. macOS asks you to confirm."
        case .denied:
            "Enable Thravik in System Settings → Privacy & Security → Passkeys Access for Web Browsers."
        case .authorized:
            "Websites can use your saved passkeys. Reload the sign-in page after granting access."
        }
    }
}
