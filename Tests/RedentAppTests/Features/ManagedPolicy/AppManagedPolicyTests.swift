import Foundation
@testable import Redent
import RedentKit
import Synchronization
import Testing

@MainActor
struct AppManagedPolicyTests {
    @Test func unchangedPolicyNeverNotifies() {
        let provider = SwitchablePolicy()
        let managed = AppManagedPolicy(provider: provider)
        var changes = 0
        managed.onChange = { changes += 1 }
        managed.refresh()
        managed.refresh()
        #expect(changes == 0)
        #expect(managed.locked.isEmpty)
        #expect(!managed.urlIsBlocked(URL(fileURLWithPath: "/")))
    }

    @Test func savesMergeAgainstThePolicyWindowsWereBuiltFrom() {
        let provider = SwitchablePolicy()
        provider.set(ManagedPolicy(homepageURL: "https://managed.test"))
        let managed = AppManagedPolicy(provider: provider)
        #expect(managed.applied.current().homepageURL == "https://managed.test")

        provider.set(ManagedPolicy())
        #expect(managed.applied.current().homepageURL == "https://managed.test")

        var changes = 0
        managed.onChange = { changes += 1 }
        managed.refresh()
        #expect(changes == 1)
        #expect(!managed.applied.current().isActive)
        #expect(managed.locked.isEmpty)
    }
}

private final class SwitchablePolicy: ManagedPolicyProviding {
    private let state = Mutex(ManagedPolicy())
    func set(_ policy: ManagedPolicy) { state.withLock { $0 = policy } }
    func current() -> ManagedPolicy { state.withLock { $0 } }
}
