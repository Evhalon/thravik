import Foundation

/// Serializes password sync and workspace sync. They share one SQLite cursor.
@MainActor
final class SyncTurnstile {
    private var locked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func run<T>(_ operation: () async throws -> T) async throws -> T {
        while locked {
            await withCheckedContinuation { waiters.append($0) }
        }
        locked = true
        defer { unlock() }
        return try await operation()
    }

    private func unlock() {
        locked = false
        guard !waiters.isEmpty else { return }
        waiters.removeFirst().resume()
    }
}
