import Foundation
import RedentKit

actor ControlledPasswordSaveStore: CredentialStoring {
    private var continuation: CheckedContinuation<Void, any Error>?
    private var started: CheckedContinuation<Void, Never>?
    private var identifiers: [UUID] = []

    func waitForSave() async {
        if continuation != nil { return }
        await withCheckedContinuation { started = $0 }
    }
    func finish(_ error: (any Error)? = nil) {
        if let error { continuation?.resume(throwing: error) }
        else { continuation?.resume() }
        continuation = nil
    }
    func savedIDs() -> [UUID] { identifiers }
    func credentials(for origin: Origin) -> [Credential] { [] }
    func allCredentials() -> [Credential] { [] }
    func save(_ credential: Credential) async throws {
        identifiers.append(credential.id)
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            started?.resume()
            started = nil
        }
    }
    func markUsed(_ id: UUID) {}
    func delete(_ id: UUID) {}
}
