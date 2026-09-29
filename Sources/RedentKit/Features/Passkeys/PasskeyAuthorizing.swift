import Foundation

public protocol PasskeyAuthorizing: Sendable {
    func currentAccess() async -> BrowserPasskeyAccess
    func requestAccess() async -> BrowserPasskeyAccess
}
