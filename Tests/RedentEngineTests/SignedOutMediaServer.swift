import Foundation
import Network
import Testing

/// A loopback server that plays the part of an Octane instance: the page's own
/// fetch gets the video, while the player's byte-range requests — the ones that
/// arrive without the page's session — get a `206` wrapped around a sign-in
/// page, exactly as the real server answers them.
final class SignedOutMediaServer: Sendable {
    private let listener: NWListener
    private let video: Data
    private let servesVideoToFetch: Bool

    init(video: Data, servesVideoToFetch: Bool = true) throws {
        listener = try NWListener(using: .tcp, on: .any)
        self.video = video
        self.servesVideoToFetch = servesVideoToFetch
    }

    /// - Returns: the page's address once the listener is accepting.
    func start() async throws -> URL {
        let port = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UInt16, any Error>) in
            listener.stateUpdateHandler = { [listener] state in
                switch state {
                case .ready:
                    listener.stateUpdateHandler = nil
                    continuation.resume(returning: listener.port?.rawValue ?? 0)
                case let .failed(error):
                    listener.stateUpdateHandler = nil
                    continuation.resume(throwing: error)
                default:
                    break
                }
            }
            listener.newConnectionHandler = { [self] connection in serve(connection) }
            listener.start(queue: .global())
        }
        return try #require(URL(string: "http://127.0.0.1:\(port)/"))
    }

    func stop() {
        listener.cancel()
    }

    private func serve(_ connection: NWConnection) {
        connection.start(queue: .global())
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [self] data, _, _, _ in
            let request = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            connection.send(content: response(to: request), completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    private func response(to request: String) -> Data {
        let path = request.split(separator: " ", maxSplits: 2).dropFirst().first ?? "/"
        guard path.hasSuffix(".mp4") else {
            return reply("200 OK", type: "text/html", body: Data(Self.page.utf8))
        }
        let signIn = Data(Self.signInPage.utf8)
        if request.range(of: "\r\nRange:", options: .caseInsensitive) != nil {
            let range = "Content-Range: bytes 0-\(signIn.count - 1)/\(signIn.count)\r\n"
            return reply("206 Partial Content", type: "text/html", body: signIn, extra: range)
        }
        guard servesVideoToFetch else { return reply("401 Unauthorized", type: "text/html", body: signIn) }
        return reply("200 OK", type: "video/mp4", body: video)
    }

    private func reply(_ status: String, type: String, body: Data, extra: String = "") -> Data {
        let head = "HTTP/1.1 \(status)\r\nContent-Type: \(type)\r\nContent-Length: \(body.count)\r\n"
            + "Accept-Ranges: bytes\r\n\(extra)Connection: close\r\n\r\n"
        return Data(head.utf8) + body
    }

    private static let page = "<body><video id='v' src='/clip.mp4' muted></video></body>"
    private static let signInPage = "<!doctype html><p>HTTP ERROR 401 Not Authenticated</p>"
}
