import RedentKit
import WebKit

@MainActor
final class WebPageFinder {
    let frames = FindFrameRegistry()
    private var requestID: UInt = 0
    private var pending: Task<FindMatches, Never>?

    func search(_ text: String, forward: Bool, in view: WKWebView) async -> FindMatches {
        guard !text.isEmpty else { clear(in: view); return .empty }
        requestID &+= 1
        let request = requestID
        let previous = pending
        let task = Task { [weak self, weak view] in
            _ = await previous?.value
            guard let self, let view, request == self.requestID else { return FindMatches.empty }
            let registration = self.frames.begin(in: view)
            _ = try? await view.callAsyncJavaScript(
                "if (window.redentFindRegister) await window.redentFindRegister(registration);",
                arguments: ["registration": registration], in: nil, contentWorld: PageScripts.contentWorld
            )
            guard request == self.requestID else { return FindMatches.empty }
            await self.runBridge("redentFindPrepare", in: view)
            guard request == self.requestID else {
                await self.runBridge("redentFindFinish", in: view)
                return FindMatches.empty
            }
            let matches = await WebNativeFind.search(text, forward: forward, in: view)
            await self.runBridge("redentFindFinish", in: view)
            return request == self.requestID ? matches : .empty
        }
        pending = task
        let matches = await task.value
        return Task.isCancelled ? .empty : matches
    }

    private func runBridge(_ name: String, in view: WKWebView) async {
        let script = "window.\(name) && window.\(name)();"
        _ = try? await view.callAsyncJavaScript(script, in: nil, contentWorld: PageScripts.contentWorld)
        for frame in frames.allFrames where !frame.isMainFrame {
            _ = try? await view.callAsyncJavaScript(script, in: frame, contentWorld: PageScripts.contentWorld)
        }
    }

    func clear(in view: WKWebView) {
        requestID &+= 1
        let previous = pending
        // Native work already sent to WebKit must finish before clearing its selection.
        let registeredFrames = frames.allFrames.filter { !$0.isMainFrame }
        pending = Task { [weak view] in
            _ = await previous?.value
            guard let view else { return .empty }
            let script = "window.redentFindClear && window.redentFindClear();"
            _ = try? await view.callAsyncJavaScript(script, in: nil, contentWorld: PageScripts.contentWorld)
            for frame in registeredFrames {
                _ = try? await view.callAsyncJavaScript(script, in: frame, contentWorld: PageScripts.contentWorld)
            }
            return .empty
        }
    }
}
