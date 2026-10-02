import RedentKit
import WebKit

@MainActor
final class WebPageFinder {
    let frames = FindFrameRegistry()
    private var requestID: UInt = 0
    private var query = ""
    private var activePath: [Int]?
    private var documentID: String?

    func search(_ text: String, forward: Bool, in view: WKWebView) async -> FindMatches {
        guard !text.isEmpty else { clear(in: view); return .empty }
        requestID &+= 1
        let request = requestID
        guard let snapshot = await scan(text, request: request, forward: forward, in: view) else {
            return await nativeSearch(text, request: request, forward: forward, in: view)
        }
        guard request == requestID, !Task.isCancelled else { return .empty }
        clearUnusedFrames(snapshot, request: request, in: view)
        guard snapshot.total > 0 else {
            query = text
            activePath = nil
            return await nativeSearch(text, request: request, forward: forward, in: view)
        }
        let retainedPath = activePath.flatMap { snapshot.containsCandidate(in: $0) ? $0 : nil }
        var index = snapshot.candidateIndex(in: retainedPath, backward: !forward)
        if query == text, retainedPath != nil {
            index = (index + (forward ? 1 : -1) + snapshot.total) % snapshot.total
        }
        guard let location = snapshot.location(at: index) else { return .empty }
        await activate(location, snapshot: snapshot, request: request, in: view)
        guard request == requestID, !Task.isCancelled else { return .empty }
        query = text
        activePath = location.path
        return FindMatches(total: snapshot.total, current: index + 1)
    }

    private func scan(_ text: String, request: UInt, forward: Bool, in view: WKWebView) async -> FindPageSnapshot? {
        let registration = frames.begin(in: view)
        _ = try? await view.callAsyncJavaScript(
            "if (window.redentFindRegister) await window.redentFindRegister(registration);",
            arguments: ["registration": registration], in: nil, contentWorld: PageScripts.contentWorld
        )
        guard request == requestID, !Task.isCancelled else { return nil }
        if documentID != frames.mainDocumentID {
            documentID = frames.mainDocumentID
            query = ""
            activePath = nil
        }
        let scanner = FindPageScanner(view: view, frames: frames, query: text, requestID: request, forward: forward)
        return await scanner.scan()
    }

    private func nativeSearch(_ text: String, request: UInt, forward: Bool, in view: WKWebView) async -> FindMatches {
        guard request == requestID, !Task.isCancelled else { return .empty }
        let result = await WebNativeFind.search(text, forward: forward, in: view)
        return request == requestID && !Task.isCancelled ? result : .empty
    }

    func clear(in view: WKWebView) {
        requestID &+= 1
        query = ""
        activePath = nil
        let script = "window.redentFindClear && window.redentFindClear(\(requestID));"
        view.evaluateJavaScript(script, in: nil, in: PageScripts.contentWorld) { _ in }
        for frame in frames.allFrames where !frame.isMainFrame {
            view.evaluateJavaScript(script, in: frame, in: PageScripts.contentWorld) { _ in }
        }
    }

    private func activate(
        _ location: FindPageSnapshot.Location, snapshot: FindPageSnapshot, request: UInt, in view: WKWebView
    ) async {
        var visited: Set<[Int]> = []
        for section in snapshot.sections {
            guard request == requestID, !Task.isCancelled else { return }
            guard visited.insert(section.path).inserted else { continue }
            let index = section.path == location.path ? location.localIndex : -1
            _ = try? await view.callAsyncJavaScript(
                "return window.redentFindActivate(index, requestID)",
                arguments: ["index": index, "requestID": request], in: section.frame,
                contentWorld: PageScripts.contentWorld
            )
        }
        await revealAncestors(of: location.path, request: request, in: view)
    }

    private func clearUnusedFrames(_ snapshot: FindPageSnapshot, request: UInt, in view: WKWebView) {
        let scanned = Set(snapshot.sections.compactMap { $0.frame }.map(ObjectIdentifier.init))
        for frame in frames.allFrames where !frame.isMainFrame && !scanned.contains(ObjectIdentifier(frame)) {
            view.evaluateJavaScript("window.redentFindClear && window.redentFindClear(\(request));",
                                    in: frame, in: PageScripts.contentWorld) { _ in }
        }
    }

    private func revealAncestors(of path: [Int], request: UInt, in view: WKWebView) async {
        for depth in path.indices.reversed() {
            guard request == requestID, !Task.isCancelled else { return }
            let parent = Array(path.prefix(depth))
            let frame = parent.isEmpty ? nil : frames.frame(at: parent)
            guard parent.isEmpty || frame != nil else { continue }
            _ = try? await view.callAsyncJavaScript(
                "window.redentFindRevealFrame(index)", arguments: ["index": path[depth]],
                in: frame, contentWorld: PageScripts.contentWorld
            )
        }
    }
}
