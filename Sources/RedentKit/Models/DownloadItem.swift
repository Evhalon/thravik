import Foundation

/// One file the browser is fetching, or has fetched.
///
/// The whole item is value-typed and `Sendable` so the engine can hand a fresh
/// copy to the UI on every progress tick without either side sharing mutable
/// state.
public struct DownloadItem: Identifiable, Sendable, Equatable {
    public enum State: Sendable, Equatable {
        case running
        case finished
        case cancelled
        /// A short, human-readable reason. Never a page value or a query string.
        case failed(String)

        public var isActive: Bool { self == .running }
    }

    public let id: UUID
    public var filename: String
    /// Where the file landed. Only set once the destination is decided.
    public var destination: URL?
    /// The site the file came from, for the row's caption.
    public var host: String?
    public var bytesReceived: Int64
    /// `nil` when the server sent no length.
    public var bytesExpected: Int64?
    public var state: State
    public let startedAt: Date

    public init(
        id: UUID = UUID(),
        filename: String,
        destination: URL? = nil,
        host: String? = nil,
        bytesReceived: Int64 = 0,
        bytesExpected: Int64? = nil,
        state: State = .running,
        startedAt: Date = .now
    ) {
        self.id = id
        self.filename = filename
        self.destination = destination
        self.host = host
        self.bytesReceived = bytesReceived
        self.bytesExpected = bytesExpected
        self.state = state
        self.startedAt = startedAt
    }

    /// `nil` when the total size is unknown — the row then draws an
    /// indeterminate bar rather than pretending to know how far along it is.
    public var fraction: Double? {
        guard let bytesExpected, bytesExpected > 0 else { return nil }
        return min(1, Double(bytesReceived) / Double(bytesExpected))
    }

    public var isActive: Bool { state.isActive }

    /// "1.2 MB of 8.4 MB", or just what has arrived when the size is unknown.
    public var sizeCaption: String {
        let received = Self.format(bytesReceived)
        guard let bytesExpected, bytesExpected > 0 else { return received }
        return "\(received) of \(Self.format(bytesExpected))"
    }

    public static func format(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: max(0, bytes))
    }
}
