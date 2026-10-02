import WebKit

@MainActor
struct FindPageScanner {
    let view: WKWebView
    let frames: FindFrameRegistry
    let query: String
    let requestID: UInt
    let forward: Bool

    func scan(path: [Int] = []) async -> FindPageSnapshot? {
        guard !Task.isCancelled, path.count <= 32 else { return nil }
        let frame = path.isEmpty ? nil : frames.frame(at: path)
        guard path.isEmpty || frame != nil else { return nil }
        let reply = try? await view.callAsyncJavaScript(
            """
            if (!window.redentFindRefresh) return null;
            return { result: window.redentFindRefresh(query, requestID, forward), slots: window.redentFindFrameSlots() };
            """,
            arguments: ["query": query, "requestID": requestID, "forward": forward], in: frame,
            contentWorld: PageScripts.contentWorld
        )
        guard let payload = reply as? [String: Any], let result = payload["result"] as? [String: Int],
              let total = result["total"], total >= 0, let current = result["current"] else { return nil }
        let slots = payload["slots"] as? [[String: Int]] ?? []
        var snapshot = FindPageSnapshot()
        var start = 0
        for slot in slots {
            guard let child = slot["index"], child >= 0, let before = slot["before"] else { continue }
            let boundary = min(max(before, start), total)
            snapshot.sections.append(.init(path: path, frame: frame, range: start..<boundary, candidate: current - 1))
            if let nested = await scan(path: path + [child]) { snapshot.sections += nested.sections }
            start = boundary
        }
        snapshot.sections.append(.init(path: path, frame: frame, range: start..<total, candidate: current - 1))
        return snapshot
    }
}
