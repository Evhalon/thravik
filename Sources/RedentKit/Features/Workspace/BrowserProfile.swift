import Foundation

public struct BrowserProfile: Codable, Sendable, Equatable {
    public var displayName: String
    public var purpose: String

    public init(displayName: String, purpose: String) {
        self.displayName = displayName
        self.purpose = purpose
    }
}
