import Foundation
import RedentKit

extension CommandBarModel {
    public struct Configuration {
        public var history: any HistoryStoring
        public var bookmarks: any BookmarkStoring
        public var context: CommandBarContext
        public var searchRouting: SearchRouting
        public var descriptors: [CommandDescriptor]
        public var onExecute: ActionHandler?

        public var searchEngine: SearchEngine {
            get { searchRouting.engine }
            set { searchRouting.engine = newValue }
        }

        public init(history: any HistoryStoring, bookmarks: any BookmarkStoring) {
            self.history = history
            self.bookmarks = bookmarks
            self.context = .init()
            self.searchRouting = SearchRouting(engine: .duckduckgo)
            self.descriptors = DefaultCommandDescriptors.all
            self.onExecute = nil
        }
    }
}
