import Foundation

/// Safe, durable summary of the latest browser import.
public struct BrowserImportReceipt: Codable, Hashable, Sendable {
    public let summary: ImportSummary
    public let profileNames: [String]
    public let problem: String?

    public init(summary: ImportSummary, profileNames: [String], problem: String?) {
        self.summary = summary
        self.profileNames = profileNames
        self.problem = problem
    }
}
