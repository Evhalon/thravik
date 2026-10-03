import Foundation
import RedentKit
import RedentSync
import RedentUI

@MainActor
final class AppWorkspaceSync {
    let model = WorkspaceSyncModel()
    private var cloud: AppCloudPasswords?
    private var turnstile: SyncTurnstile?
    private var accountID: UUID?
    private var store: (any WorkspaceSyncing)?
    private var task: Task<Void, Never>?
    private var pending: BrowserSession?
    private var flushedAt = Date.distantPast
    private var force = false
    private var running = false
    private var queued = false
    private var prepared = false
    var apply: ((WorkspaceSyncSnapshot) -> Void)?
    var refreshSession: (() async -> Void)?
    var syncAllowed = true
    private let makeStore: (@MainActor (UUID) -> any WorkspaceSyncing)?

    init(makeStore: (@MainActor (UUID) -> any WorkspaceSyncing)? = nil) { self.makeStore = makeStore }

    func attach(cloud: AppCloudPasswords, turnstile: SyncTurnstile) {
        self.cloud = cloud
        self.turnstile = turnstile
    }

    func accountChanged(_ session: AccountSession?) {
        guard accountID != session?.accountID else { return }
        if let accountID { cloud?.discardReplica(accountID: accountID) }
        accountID = session?.accountID
        store = nil
        prepared = false
        pending = nil
        model.replace([])
        model.recordSyncedProfile(nil)
        model.note(nil)
        if session != nil { schedule(forced: true) }
    }

    func note(_ session: BrowserSession) {
        guard syncAllowed else { return }
        pending = session
        if running { queued = true } else { schedule() }
    }

    func schedule(forced: Bool = false) {
        guard syncAllowed else { return }
        if forced { force = true }
        if running {
            queued = true
            return
        }
        task?.cancel()
        task = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { return }
                try await self.turnstile?.run { await self.run() }
            } catch is CancellationError { }
            catch { self?.model.note("Workspace sync is unavailable. Local changes were kept.") }
        }
    }

    /// Caller already holds the turnstile. A nested lock would wait forever.
    func flush() async {
        guard syncAllowed else { return }
        await run()
    }

    private func run() async {
        guard pending != nil || force || Date().timeIntervalSince(flushedAt) >= 1 else { return }
        force = false
        running = true
        var followUp = false
        defer {
            running = false
            let again = queued || followUp
            queued = false
            if again { schedule(forced: followUp) }
        }
        await refreshSession?()
        guard let accountID else { return }
        if store == nil { store = makeStore?(accountID) ?? cloud?.makeWorkspaceStore(accountID: accountID) }
        guard let store else { return }
        if !prepared {
            followUp = await pull(store)
            guard prepared, !followUp else { return }
        }
        guard store === self.store else { return }
        let published = await publish(store)
        guard published == .done else {
            if published == .retry { followUp = true }
            return
        }
        followUp = await pull(store)
    }

    private enum Step {
        case done
        case retry
        case stop
    }

    private func publish(_ store: any WorkspaceSyncing) async -> Step {
        guard let pending else { return .done }
        do {
            try await store.publish(pending)
            guard store === self.store else { return .stop }
            if self.pending == pending { self.pending = nil }
            return .done
        } catch SyncError.alreadyRunning {
            return .retry
        } catch SyncError.unauthorized {
            return .stop
        } catch is CancellationError {
            return .stop
        } catch {
            model.note("Workspace could not be saved to the account.")
            return .stop
        }
    }

    private func pull(_ store: any WorkspaceSyncing) async -> Bool {
        do {
            let (snapshot, hasMore) = try await store.synchronize()
            guard store === self.store else { return false }
            prepared = !hasMore
            apply?(snapshot)
            flushedAt = .now
            model.note(nil)
            return hasMore
        } catch SyncError.unauthorized {
            return false
        } catch SyncError.alreadyRunning {
            return true
        } catch is CancellationError {
            return false
        } catch {
            model.note("Workspace could not be synchronized.")
            return false
        }
    }
}
