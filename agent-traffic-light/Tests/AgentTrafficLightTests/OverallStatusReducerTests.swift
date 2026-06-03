import XCTest
@testable import AgentTrafficLight

final class OverallStatusReducerTests: XCTestCase {
    private let reducer = OverallStatusReducer()

    func testEmptySnapshotsReturnUnknown() {
        XCTAssertEqual(reducer.reduce([]), .unknown)
    }

    func testWaitingForUserHasHighestPriority() {
        let snapshots = [
            snapshot("codex", .working),
            snapshot("claude", .waitingForUser),
            snapshot("cursor", .error)
        ]

        XCTAssertEqual(reducer.reduce(snapshots), .waitingForUser)
    }

    func testWorkingHasPriorityOverErrorAndUnknown() {
        let snapshots = [
            snapshot("codex", .unknown),
            snapshot("claude", .error),
            snapshot("cursor", .working)
        ]

        XCTAssertEqual(reducer.reduce(snapshots), .working)
    }

    func testErrorHasPriorityOverUnknownAndIdle() {
        let snapshots = [
            snapshot("codex", .idle),
            snapshot("claude", .unknown),
            snapshot("cursor", .error)
        ]

        XCTAssertEqual(reducer.reduce(snapshots), .error)
    }

    func testUnknownHasPriorityOverIdle() {
        let snapshots = [
            snapshot("codex", .idle),
            snapshot("claude", .unknown)
        ]

        XCTAssertEqual(reducer.reduce(snapshots), .unknown)
    }

    func testAllIdleReturnsIdle() {
        let snapshots = [
            snapshot("codex", .idle),
            snapshot("claude", .idle)
        ]

        XCTAssertEqual(reducer.reduce(snapshots), .idle)
    }

    private func snapshot(_ id: String, _ state: AgentState) -> AgentSnapshot {
        AgentSnapshot(
            agentID: id,
            displayName: id,
            state: state,
            confidence: 1,
            source: "test"
        )
    }
}
