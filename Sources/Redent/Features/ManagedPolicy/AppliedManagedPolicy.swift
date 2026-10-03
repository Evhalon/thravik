import RedentKit
import Synchronization

/// The policy the open windows were last built from, readable off the main
/// actor by the settings store that merges saves against it.
final class AppliedManagedPolicy: ManagedPolicyProviding {
    private let state: Mutex<ManagedPolicy>

    init(_ policy: ManagedPolicy = ManagedPolicy()) {
        state = Mutex(policy)
    }

    func current() -> ManagedPolicy { state.withLock { $0 } }

    func update(_ policy: ManagedPolicy) { state.withLock { $0 = policy } }
}
