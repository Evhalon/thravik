import Foundation

extension PasswordStorageModel {
    public func synchronize() async {
        guard !isBusy, selectedMode == .redentCloud, availableModes.contains(.redentCloud),
              let synchronizeCloud else { return }
        var hasMore = false
        await perform {
            hasMore = try await synchronizeCloud()
            conflicts = []
            message = hasMore ? "Synchronizing remaining passwords…" : "Passwords synchronized."
        }
        if hasMore { scheduleSynchronization() }
    }

    public func resolve(id: UUID, keepingLocal: Bool) async {
        guard !isBusy, let resolveConflict else { return }
        await perform {
            try await resolveConflict(id, keepingLocal)
            conflicts.removeAll { $0.id == id }
        }
        scheduleSynchronization()
    }

    public func scheduleSynchronization() {
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(1)) } catch { return }
            await self?.synchronize()
        }
    }

    public func cancelSynchronization() {
        syncTask?.cancel()
        syncTask = nil
    }
}
