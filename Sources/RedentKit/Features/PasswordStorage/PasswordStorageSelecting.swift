import Foundation

public protocol PasswordStorageSelecting: Sendable {
    func selectedMode() async throws -> PasswordStorageMode
    func select(_ mode: PasswordStorageMode, copyingCurrent: Bool) async throws
}
