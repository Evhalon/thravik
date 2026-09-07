import Foundation
import os
import RedentKit

public struct OSLogEventLogger: EventLogging {
    private let logger: Logger

    public init(subsystem: String = "app.redent.browser", category: String) {
        logger = Logger(subsystem: subsystem, category: category)
    }

    public func debug(_ message: @autoclosure () -> String) {
        let text = message()
        logger.debug("\(text, privacy: .public)")
    }

    public func notice(_ message: @autoclosure () -> String) {
        let text = message()
        logger.info("\(text, privacy: .public)")
    }

    public func error(_ message: @autoclosure () -> String) {
        let text = message()
        logger.error("\(text, privacy: .public)")
    }
}
