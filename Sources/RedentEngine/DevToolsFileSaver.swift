import AppKit
import WebKit

/// Writes what DevTools saves — the console's log, a response body, a HAR —
/// to a file the user picks in a save panel, and nowhere else.
///
/// DevTools names each save by a URL of its own and then streams the rest in
/// with `append`; the file the user chose is remembered under that name.
@MainActor
final class DevToolsFileSaver {
    private weak var frontend: WKWebView?
    private var destinations: [String: URL] = [:]

    /// One `save` DevTools asked for.
    struct Request {
        let url: String
        let content: String
        let isBase64: Bool
        let forceSaveAs: Bool
    }

    init(frontend: WKWebView) {
        self.frontend = frontend
    }

    func save(_ request: Request) {
        if let known = destinations[request.url], !request.forceSaveAs {
            write(request, to: known)
            return
        }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = Self.suggestedName(for: request.url)
        panel.canCreateDirectories = true
        let finish: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard let self else { return }
            guard response == .OK, let file = panel.url else {
                self.dispatch("canceledSaveURL", request.url)
                return
            }
            self.destinations[request.url] = file
            self.write(request, to: file)
        }
        if let window = frontend?.window {
            panel.beginSheetModal(for: window, completionHandler: finish)
        } else {
            finish(panel.runModal())
        }
    }

    func append(url: String, content: String) {
        guard let file = destinations[url] else { return }
        let data = Data(content.utf8)
        Task { [weak self] in
            await Self.appending(data, to: file)
            self?.dispatch("appendedToURL", url)
        }
    }

    private func write(_ request: Request, to file: URL) {
        let data = request.isBase64 ? Data(base64Encoded: request.content) ?? Data() : Data(request.content.utf8)
        Task { [weak self] in
            let saved = await Self.writing(data, to: file)
            guard let self else { return }
            if saved {
                self.dispatch("savedURL", ["url": request.url, "fileSystemPath": file.path])
            } else {
                self.dispatch("canceledSaveURL", request.url)
            }
        }
    }

    private func dispatch(_ event: String, _ data: Any) {
        frontend?.callAsyncJavaScript(
            "InspectorFrontendHost.events?.dispatchEventToListeners(name, data)",
            arguments: ["name": event, "data": data], in: nil, in: .page
        )
    }

    private static func suggestedName(for url: String) -> String {
        let name = URL(string: url)?.lastPathComponent ?? url
        return name.isEmpty || name == "/" ? "devtools.txt" : name
    }

    /// Off the main actor: a HAR or a long console log can be large.
    private nonisolated static func writing(_ data: Data, to file: URL) async -> Bool {
        (try? data.write(to: file, options: .atomic)) != nil
    }

    private nonisolated static func appending(_ data: Data, to file: URL) async {
        guard let handle = try? FileHandle(forWritingTo: file) else { return }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: data)
    }
}
