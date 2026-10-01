import Foundation
import RedentKit

/// Runs one of the system's archive tools and hands back what it printed.
enum ArchiveTool {
    static func run(_ tool: String, _ arguments: [String]) async throws(ExtensionInstallError) -> String {
        let output = await Task.detached { runBlocking(tool, arguments) }.value
        guard let output else { throw .unpackFailed }
        return output
    }

    /// Reads the pipe to its end before waiting: a listing larger than the
    /// pipe's buffer would otherwise stall the tool and this call forever.
    private static func runBlocking(_ tool: String, _ arguments: [String]) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return nil
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(data: data, encoding: .utf8) ?? ""
    }
}
