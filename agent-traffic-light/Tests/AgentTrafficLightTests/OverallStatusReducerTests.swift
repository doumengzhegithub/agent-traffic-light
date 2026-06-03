import Testing
@testable import AgentTrafficLight

struct OverallStatusReducerTests {
    private let reducer = OverallStatusReducer()

    @Test
    func testEmptySnapshotsReturnUnknown() {
        #expect(reducer.reduce([]) == .unknown)
    }

    @Test
    func testWaitingForUserHasHighestPriority() {
        let snapshots = [
            snapshot("codex", .working),
            snapshot("claude", .waitingForUser),
            snapshot("cursor", .error)
        ]

        #expect(reducer.reduce(snapshots) == .waitingForUser)
    }

    @Test
    func testWorkingHasPriorityOverErrorAndUnknown() {
        let snapshots = [
            snapshot("codex", .unknown),
            snapshot("claude", .error),
            snapshot("cursor", .working)
        ]

        #expect(reducer.reduce(snapshots) == .working)
    }

    @Test
    func testErrorHasPriorityOverUnknownAndIdle() {
        let snapshots = [
            snapshot("codex", .idle),
            snapshot("claude", .unknown),
            snapshot("cursor", .error)
        ]

        #expect(reducer.reduce(snapshots) == .error)
    }

    @Test
    func testUnknownHasPriorityOverIdle() {
        let snapshots = [
            snapshot("codex", .idle),
            snapshot("claude", .unknown)
        ]

        #expect(reducer.reduce(snapshots) == .unknown)
    }

    @Test
    func testAllIdleReturnsIdle() {
        let snapshots = [
            snapshot("codex", .idle),
            snapshot("claude", .idle)
        ]

        #expect(reducer.reduce(snapshots) == .idle)
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
