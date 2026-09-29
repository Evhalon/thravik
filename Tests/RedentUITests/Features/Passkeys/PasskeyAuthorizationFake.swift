import RedentKit

actor PasskeyAuthorizationFake: PasskeyAuthorizing {
    private var access: BrowserPasskeyAccess
    private var continuation: CheckedContinuation<BrowserPasskeyAccess, Never>?
    private var earlyAnswer: BrowserPasskeyAccess?
    private(set) var requests = 0

    init(access: BrowserPasskeyAccess = .notDetermined) {
        self.access = access
    }

    func currentAccess() -> BrowserPasskeyAccess { access }

    func requestAccess() async -> BrowserPasskeyAccess {
        requests += 1
        if let earlyAnswer { return earlyAnswer }
        return await withCheckedContinuation { continuation = $0 }
    }

    func answer(_ access: BrowserPasskeyAccess) {
        self.access = access
        guard let continuation else {
            earlyAnswer = access
            return
        }
        self.continuation = nil
        continuation.resume(returning: access)
    }
}
