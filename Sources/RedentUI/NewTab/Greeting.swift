import Foundation

/// A greeting that tracks the clock, because a browser opened at 2am and one
/// opened at 9am are not the same moment.
enum Greeting {
    static func current(at date: Date = .now, calendar: Calendar = .current) -> String {
        switch calendar.component(.hour, from: date) {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        case 18..<23: "Good evening"
        default: "Still up?"
        }
    }
}
