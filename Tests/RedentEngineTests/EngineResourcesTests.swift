import Foundation
import Testing
@testable import RedentEngine

/// Regression cover for the 0.1.1 launch crash: `Bundle.module` trapped inside
/// `AppContainer.init` on a Mac whose copy of the app had no resource bundle.
@Suite("Engine resources")
struct EngineResourcesTests {
    @Test("The resource bundle is found where the build leaves it")
    func bundleResolves() throws {
        let bundle = try #require(EngineResources.bundle)
        #expect(bundle.url(forResource: "adblock-catalog", withExtension: "json") != nil)
        #expect(bundle.url(forResource: "redent-page", withExtension: "js") != nil)
    }

    @Test("A missing resource bundle degrades the catalog instead of trapping")
    func missingBundleReturnsNil() {
        #expect(ContentBlockCatalog.load(from: nil) == nil)
    }

    @Test("A bundle without the catalog returns nil")
    func emptyBundleReturnsNil() throws {
        let empty = try #require(Bundle(url: URL(fileURLWithPath: "/System/Library/CoreServices")))
        #expect(ContentBlockCatalog.load(from: empty) == nil)
    }
}
