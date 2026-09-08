import Foundation

/// Runs a command-line tool and suspends until it exits, rather than blocking
/// a thread on `waitUntilExit`. The update path shells out to `hdiutil`,
/// `codesign` and `ditto` — reimplementing any of them would be worse.
enum Shell {
    static func run(_ tool: String, _ arguments: [String]) async throws {
        let status = try await exitStatus(tool, arguments)
        guard status == 0 else {
            throw UpdateError.toolFailed((tool as NSString).lastPathComponent, status)
        }
    }

    /// `true` when the tool exited cleanly. For checks where a non-zero status
    /// is an answer, not a failure.
    static func succeeds(_ tool: String, _ arguments: [String]) async -> Bool {
        (try? await exitStatus(tool, arguments)) == 0
    }

    /// Starts a tool and returns without waiting. The relaunch helper has to
    /// outlive this process, so nothing may wait on it.
    static func spawn(_ tool: String, _ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
    }

    private static func exitStatus(_ tool: String, _ arguments: [String]) async throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = arguments
        // Tool output can quote a URL or a path from the disk image; none of it
        // is ours to log, and an unread pipe would deadlock a chatty tool.
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { continuation.resume(returning: $0.terminationStatus) }
            do {
                try process.run()
            } catch {
                process.terminationHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }
}
