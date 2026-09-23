import Foundation
import RedentKit

/// Every built-in command, in the order the empty bar lists them.
public enum DefaultCommandDescriptors {
    public static let all: [CommandDescriptor] =
        TabCommandDescriptors.all
        + WindowCommandDescriptors.all
        + PageCommandDescriptors.all
        + LibraryCommandDescriptors.all
}
