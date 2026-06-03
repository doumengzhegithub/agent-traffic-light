import Foundation

protocol ClockProvider: Sendable {
    var now: Date { get }
}

struct SystemClock: ClockProvider {
    var now: Date {
        Date()
    }
}
