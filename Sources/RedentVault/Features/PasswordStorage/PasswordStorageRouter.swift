import Foundation
import RedentKit

public actor PasswordStorageRouter: CredentialStoring, PasswordStorageSelecting {
    private let local: any CredentialStoring
    private let preferences: any PasswordStoragePreferenceStoring
    private let gate = PasswordOperationGate()
    private var providers: [PasswordStorageMode: any CredentialStoring] = [:]
    private var mode: PasswordStorageMode = .local
    private var initialized = false
    private var generation: UInt64 = 0

    public init(local: any CredentialStoring, preferences: any PasswordStoragePreferenceStoring) {
        self.local = local
        self.preferences = preferences
    }

    public func register(_ provider: any CredentialStoring, for mode: PasswordStorageMode) async {
        await gate.acquire()
        providers[mode] = provider
        generation &+= 1
        await gate.release()
    }

    public func unregister(_ mode: PasswordStorageMode) async {
        await gate.acquire()
        providers.removeValue(forKey: mode)
        generation &+= 1
        await gate.release()
    }

    public func selectedMode() async -> PasswordStorageMode {
        await gate.acquire()
        await initializeSelection()
        let selected = mode
        await gate.release()
        return selected
    }

    public func preferredMode() async -> PasswordStorageMode { await preferences.load() }

    public func select(_ requested: PasswordStorageMode, copyingCurrent: Bool) async throws {
        await gate.acquire()
        do {
            try Task.checkCancellation()
            await initializeSelection()
            let destination = try provider(for: requested)
            _ = try await destination.allCredentials()
            if copyingCurrent && requested != mode {
                let credentials = try await provider(for: mode).allCredentials()
                try await PasswordStorageTransfer.copy(credentials, to: destination)
            }
            try await preferences.save(requested)
            mode = requested
            generation &+= 1
            await gate.release()
        } catch {
            await gate.release()
            throw error
        }
    }

    public func credentials(for origin: Origin) async throws -> [Credential] {
        try await perform { try await $0.credentials(for: origin) }
    }

    public func allCredentials() async throws -> [Credential] {
        try await perform { try await $0.allCredentials() }
    }

    public func save(_ credential: Credential) async throws {
        try await perform { try await $0.save(credential) }
    }

    public func importCredentials(_ credentials: [Credential]) async throws -> [Credential] {
        try await perform { try await $0.importCredentials(credentials) }
    }

    public func markUsed(_ id: UUID) async throws {
        try await perform { try await $0.markUsed(id) }
    }

    public func delete(_ id: UUID) async throws {
        try await perform { try await $0.delete(id) }
    }

    private func initializeSelection() async {
        guard !initialized else { return }
        mode = await preferences.load()
        initialized = true
    }

    private func provider(for mode: PasswordStorageMode) throws -> any CredentialStoring {
        if mode == .local { return local }
        guard let provider = providers[mode] else { throw PasswordStorageError.unavailable }
        return provider
    }

    private func perform<T: Sendable>(_ action: @Sendable (any CredentialStoring) async throws -> T) async throws -> T {
        let expected = generation
        await gate.acquire()
        do {
            try Task.checkCancellation()
            await initializeSelection()
            guard generation == expected else { throw PasswordStorageError.providerChanged }
            let result = try await action(provider(for: mode))
            await gate.release()
            return result
        } catch {
            await gate.release()
            throw error
        }
    }
}
