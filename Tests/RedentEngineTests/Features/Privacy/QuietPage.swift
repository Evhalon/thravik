import Foundation
import RedentKit
import Testing
import WebKit
@testable import RedentEngine

/// Loads markup into a real tab with Quiet mode on or off, and reads it back
/// from the page's own world, where its click handlers ran.
@MainActor
enum QuietPage {
    static func load(_ body: String, quiets: Bool = true) async throws -> WebTab {
        let controller = TabController(
            session: BrowserSession(tabs: [TabSnapshot()], selectedTabID: nil),
            settings: BrowserSettings(quietsPages: quiets),
            logger: MutedLogger()
        )
        let tab = try #require(controller.webTabs.first)
        tab.wake(loading: nil)
        let view = try #require(tab.webView)
        view.loadHTMLString("<body>\(body)</body>", baseURL: URL(string: "https://news.example.com"))
        for _ in 0..<200 {
            // The blank page before the load is "complete" too; wait for this one.
            let loaded = "location.host === 'news.example.com' && document.readyState === 'complete'"
            if try await value(tab, loaded) as? Bool == true { return tab }
            try await Task.sleep(for: .milliseconds(20))
        }
        Issue.record("The page never finished loading")
        return tab
    }

    /// Half a second of 8 kHz silence: real media, so `play()` actually starts.
    static var silentWAV: String {
        let samples = 4000
        var wav = Data("RIFF".utf8)
        wav.append(littleEndian: UInt32(36 + samples))
        wav.append(contentsOf: Data("WAVEfmt ".utf8))
        wav.append(littleEndian: UInt32(16))
        wav.append(littleEndian: UInt16(1))
        wav.append(littleEndian: UInt16(1))
        wav.append(littleEndian: UInt32(8000))
        wav.append(littleEndian: UInt32(8000))
        wav.append(littleEndian: UInt16(1))
        wav.append(littleEndian: UInt16(8))
        wav.append(contentsOf: Data("data".utf8))
        wav.append(littleEndian: UInt32(samples))
        wav.append(Data(repeating: 128, count: samples))
        return "data:audio/wav;base64,\(wav.base64EncodedString())"
    }

    static func value(_ tab: WebTab, _ expression: String) async throws -> Any? {
        try await tab.webView?.callAsyncJavaScript("return \(expression)", in: nil, contentWorld: .page)
    }

    static func settles(_ tab: WebTab, _ condition: String) async throws -> Bool {
        try await settlesNative { (try? await value(tab, condition)) as? Bool == true }
    }

    static func settlesNative(_ condition: () async -> Bool) async throws -> Bool {
        for _ in 0..<150 {
            if await condition() { return true }
            try await Task.sleep(for: .milliseconds(20))
        }
        return false
    }
}

private extension Data {
    mutating func append<Value: FixedWidthInteger>(littleEndian value: Value) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: $0) }
    }
}

private struct MutedLogger: EventLogging {
    func debug(_ message: @autoclosure () -> String) {}
    func notice(_ message: @autoclosure () -> String) {}
    func error(_ message: @autoclosure () -> String) {}
}
