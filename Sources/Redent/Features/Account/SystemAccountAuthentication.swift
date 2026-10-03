import AppKit
import RedentKit

/// A system-browser attempt owns its callback, timeout and cancellation token.
@MainActor
final class SystemAccountAuthentication {
    private var continuation: CheckedContinuation<URL, any Error>?
    private var timeout: Task<Void, Never>?
    private var attemptID: UUID?
    private var callback: SystemAccountCallback?
    private let browserOpener: @MainActor (URL) async throws -> Void
    private let activate: @MainActor () -> Void

    init(browserOpener: (@MainActor (URL) async throws -> Void)? = nil,
         activate: (@MainActor () -> Void)? = nil) {
        self.browserOpener = browserOpener ?? { try await Self.openBrowser($0) }
        self.activate = activate ?? { NSApp?.activate() }
    }

    func authenticate(url: URL) async throws -> URL {
        guard continuation == nil else { throw AccountError.unavailable }
        try Task.checkCancellation()
        let callback = try SystemAccountCallback(authorizationURL: url)
        let id = UUID()
        attemptID = id
        self.callback = callback
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                begin(url: url, id: id)
            }
        } onCancel: {
            Task { @MainActor [weak self] in self?.resume(.failure(CancellationError()), id: id) }
        }
    }

    func accept(_ url: URL) -> Bool {
        guard url.scheme == "redent", url.host == "account", url.path == "/callback" else { return false }
        guard let id = attemptID, continuation != nil else { return true }
        guard callback?.matches(url) == true else { return true }
        activate()
        resume(.success(url), id: id)
        return true
    }

    private func begin(url: URL, id: UUID) {
        timeout = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(180)) } catch { return }
            self?.resume(.failure(CancellationError()), id: id)
        }
        Task { @MainActor [weak self] in
            guard let self, self.attemptID == id else { return }
            do { try await browserOpener(url) }
            catch { resume(.failure(error), id: id) }
        }
    }

    private static func openBrowser(_ url: URL) async throws {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        let safari = URL(fileURLWithPath: "/Applications/Safari.app")
        if FileManager.default.fileExists(atPath: safari.path) {
            do {
                _ = try await NSWorkspace.shared.open([url], withApplicationAt: safari, configuration: configuration)
                return
            } catch { }
        }
        guard NSWorkspace.shared.open(url) else { throw AccountError.unavailable }
    }

    private func resume(_ result: Result<URL, any Error>, id: UUID) {
        guard attemptID == id else { return }
        let pending = continuation
        continuation = nil
        attemptID = nil
        callback = nil
        timeout?.cancel()
        timeout = nil
        pending?.resume(with: result)
    }
}
