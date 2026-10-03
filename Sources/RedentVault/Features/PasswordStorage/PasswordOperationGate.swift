import Foundation

/// Keychain read-modify-write spans awaits; the gate keeps provider changes outside that span.
actor PasswordOperationGate {
    private var occupied = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        if !occupied { occupied = true; return }
        await withCheckedContinuation { waiting.append($0) }
    }

    func release() {
        guard !waiting.isEmpty else { occupied = false; return }
        waiting.removeFirst().resume()
    }
}
