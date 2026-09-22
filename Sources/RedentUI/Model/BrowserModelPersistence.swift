import Foundation
import RedentKit

/// When the workspace is written to disk, and on which thread.
extension BrowserModel {
    public func resetWorkspace() {
        split = SplitLayout()
        tabs.resetWorkspace()
        persistSession()
    }

    /// The explicit save: closing the window, or quitting. Synchronous, because
    /// the process may not live long enough for anything else to finish.
    public func persistSession() {
        persistSettings()
        hasUnsavedChanges = false
        lastSave = .now
        // A periodic save may still be queued behind an older write. Cancel it
        // before the closing snapshot is written so stale tabs cannot win last.
        saveTask?.cancel()
        saveTask = nil
        do { try sessionStore.saveRecoverable(durableSession()) }
        catch { actionError = "Workspace could not be saved. Existing saved data was preserved." }
    }

    /// The periodic flush. Encoding a large workspace costs milliseconds, and
    /// the main thread is where frames get drawn, so the write happens off it.
    /// Saves are chained rather than fired in parallel: they share one file.
    func persistIfNeeded(_ now: Date) {
        guard now.timeIntervalSince(lastSave) >= Self.saveInterval else { return }
        guard hasUnsavedChanges || hasUnsavedSettings else { return }
        persistSettings()
        hasUnsavedChanges = false
        lastSave = now

        let session = durableSession()
        let previous = saveTask
        let task: Task<Bool?, Never> = Task.detached(priority: .utility) { [sessionStore] in
            _ = await previous?.value
            guard !Task.isCancelled else { return nil }
            return (try? sessionStore.saveRecoverable(session)) != nil
        }
        saveTask = task
        Task { [weak self] in
            guard let saved = await task.value, !saved else { return }
            self?.actionError = "Workspace could not be saved. Existing saved data was preserved."
        }
    }

    func persistSettings() {
        guard hasUnsavedSettings else { return }
        hasUnsavedSettings = false
        settingsStore.save(settings)
    }

    private func durableSession() -> BrowserSession {
        var session = tabs.session
        session.splitLayout = split
        return session
    }

    /// Long enough that a burst of navigation events collapses into one write,
    /// short enough that a crash costs a second of workspace state at most.
    static let saveInterval: TimeInterval = 2
}
