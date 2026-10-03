import Foundation

public protocol PasswordStoragePreferenceStoring: Sendable {
    func load() async -> PasswordStorageMode
    func save(_ mode: PasswordStorageMode) async throws
}
