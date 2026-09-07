import SwiftUI
import Foundation

public struct BrowserPageView: View {
    private let controller: TabController
    private let tabID: UUID

    public init(controller: TabController, tabID: UUID) {
        self.controller = controller
        self.tabID = tabID
    }

    public var body: some View {
        Group {
            if let tab = controller.webTabs.first(where: { $0.id == tabID }) {
                WebContentView(tab: tab)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
    }
}
