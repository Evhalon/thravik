import Foundation
import RedentKit
import Testing
@testable import RedentEngine

@MainActor
@Suite("Cached PDF downloads")
struct DownloadDataSessionTests {
    @Test("Cached PDF bytes are saved unchanged and published as finished")
    func savesCachedBytes() async throws {
        let observer = DataDownloadObserver()
        let coordinator = DownloadCoordinator(logger: DataDownloadLogger())
        coordinator.observer = observer
        let session = DownloadDataSession(filename: "../sample.pdf", host: "pdfobject.com", coordinator: coordinator)
        let bytes = Data("%PDF-1.7\noriginal bytes".utf8)
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: destination) }
        session.start(bytes) { data, filename in
            #expect(filename == "sample.pdf")
            try data.write(to: destination)
            return destination
        }
        await observer.waitForCompletion()
        #expect(try Data(contentsOf: destination) == bytes)
        #expect(observer.items.first?.state == .running)
        #expect(observer.items.last?.state == .finished)
        #expect(observer.items.last?.destination == destination)
        #expect(observer.items.last?.bytesReceived == Int64(bytes.count))
        #expect(observer.items.last?.host == "pdfobject.com")
    }

    @Test("A failed save publishes failure without a destination")
    func reportsFailure() async {
        let observer = DataDownloadObserver()
        let coordinator = DownloadCoordinator(logger: DataDownloadLogger())
        coordinator.observer = observer
        let session = DownloadDataSession(filename: "sample.pdf", host: nil, coordinator: coordinator)
        session.start(Data()) { _, _ in throw SaveFailure.unavailable }
        await observer.waitForCompletion()
        #expect(observer.items.last?.state == .failed("The file could not be saved to Downloads."))
        #expect(observer.items.last?.destination == nil)
    }

    @Test("Cancellation is terminal and cannot turn into a save failure")
    func cancellationIsTerminal() async {
        let observer = DataDownloadObserver()
        let coordinator = DownloadCoordinator(logger: DataDownloadLogger())
        coordinator.observer = observer
        let session = DownloadDataSession(filename: "sample.pdf", host: nil, coordinator: coordinator)
        session.start(Data()) { _, _ in throw SaveFailure.unavailable }
        session.cancel()
        await observer.waitForCompletion()
        #expect(observer.items.last?.state == .cancelled)
        #expect(observer.items.count == 2)
    }

    private enum SaveFailure: Error { case unavailable }
}

@MainActor
private final class DataDownloadObserver: DownloadObserving {
    var items: [DownloadItem] = []
    private var completion: CheckedContinuation<Void, Never>?

    func downloadChanged(_ item: DownloadItem) {
        items.append(item)
        guard !item.isActive else { return }
        completion?.resume()
        completion = nil
    }

    func waitForCompletion() async {
        guard items.last?.isActive != false else { return }
        await withCheckedContinuation { completion = $0 }
    }
}

private struct DataDownloadLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
