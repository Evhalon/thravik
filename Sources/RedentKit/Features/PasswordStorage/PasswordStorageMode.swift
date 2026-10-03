import Foundation

public enum PasswordStorageMode: String, CaseIterable, Codable, Sendable {
    case local
    case redentCloud
    case iCloud
}
