import Foundation

public enum BrowserPasskeyAccess: Sendable, Equatable {
    case unavailable
    case notDetermined
    case denied
    case authorized
}
