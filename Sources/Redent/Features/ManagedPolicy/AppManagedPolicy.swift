import AppKit
import Foundation
import RedentKit
import RedentVault

@MainActor
final class AppManagedPolicy {
    private(set) var policy = ManagedPolicy()
    private(set) var locked = Set<ManagedPolicyLockKey>()
    let applied = AppliedManagedPolicy()
    private let provider: any ManagedPolicyProviding
    private var observers: [NSObjectProtocol] = []
    var onChange: (() -> Void)?

    init(provider: any ManagedPolicyProviding = UserDefaultsManagedPolicyProvider()) {
        self.provider = provider
        refresh(silent: true)
        // A profile pushed while Redent runs does not always post a defaults
        // change in this process; activation is the next cheap chance to see it.
        let names = [UserDefaults.didChangeNotification, NSApplication.didBecomeActiveNotification]
        observers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            }
        }
    }

    /// Cheap and side-effect free unless the policy changed: the app's own
    /// defaults writes land here too.
    func refresh(silent: Bool = false) {
        let next = provider.current()
        guard next != policy else { return }
        policy = next
        locked = ManagedPolicyApplication.apply(user: BrowserSettings(), policy: next).locked
        applied.update(next)
        guard !silent else { return }
        onChange?()
    }

    func urlIsBlocked(_ url: URL) -> Bool {
        ManagedURLBlocklist.isBlocked(url: url, patterns: policy.blockedURLPatterns ?? [])
    }

    var privateWindowsAllowed: Bool { policy.disablePrivateWindows != true }
    var accountSyncAllowed: Bool { policy.disableAccountSync != true }
}
