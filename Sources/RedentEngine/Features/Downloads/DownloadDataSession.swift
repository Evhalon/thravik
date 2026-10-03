import Foundation
import RedentKit

@MainActor
final class DownloadDataSession {
    typealias Writer = @Sendable (Data, String) throws -> URL

    private(set) var item: DownloadItem
    private weak var coordinator: DownloadCoordinator?
    private var writeTask: Task<URL, any Error>?

    var id: UUID { item.id }

    init(filename: String, host: String?, coordinator: DownloadCoordinator) {
        item = DownloadItem(filename: DownloadDestination.sanitize(filename), host: host)
        self.coordinator = coordinator
    }

    func start(_ data: Data, writer: @escaping Writer = DownloadDestination.save) {
        item.bytesExpected = Int64(data.count)
        coordinator?.observer?.downloadChanged(item)
        let filename = item.filename
        let task = Task.detached {
            try Task.checkCancellation()
            return try writer(data, filename)
        }
        writeTask = task
        Task { await finishWriting(task) }
    }

    func cancel() {
        guard item.isActive else { return }
        writeTask?.cancel()
        finish(with: .cancelled)
    }

    private func finishWriting(_ task: Task<URL, any Error>) async {
        do {
            let destination = try await task.value
            guard item.isActive else {
                _ = await Task.detached { try? FileManager.default.removeItem(at: destination) }.value
                return
            }
            item.destination = destination
            item.filename = destination.lastPathComponent
            item.bytesReceived = item.bytesExpected ?? 0
            finish(with: .finished)
        } catch {
            finish(with: .failed("The file could not be saved to Downloads."))
        }
        writeTask = nil
    }

    private func finish(with state: DownloadItem.State) {
        guard item.isActive else { return }
        item.state = state
        coordinator?.observer?.downloadChanged(item)
        coordinator?.sessionEnded(id)
    }
}
