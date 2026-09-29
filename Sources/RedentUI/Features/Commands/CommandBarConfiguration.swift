import Foundation
import RedentKit

extension CommandBarModel {
    public struct Configuration {
        public var history: any HistoryStoring
        public var bookmarks: any BookmarkStoring
        public var context: CommandBarContext
        public var searchEngine: SearchEngine
        public var descriptors: [CommandDescriptor]
        public var onExecute: ActionHandler?

        public init(history: any HistoryStoring, bookmarks: any BookmarkStoring) {
            self.history = history
            self.bookmarks = bookmarks
            self.context = .init()
            self.searchEngine = .duckduckgo
            self.descriptors = DefaultCommandDescriptors.all
            self.onExecute = nil
        }
    }
}
