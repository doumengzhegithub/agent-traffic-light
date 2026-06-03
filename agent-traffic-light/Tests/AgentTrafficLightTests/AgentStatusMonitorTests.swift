import Foundation
import Testing
@testable import AgentTrafficLight

struct AgentStatusMonitorTests {
    @Test
    func testCollectOnceAggregatesProviderSnapshots() async {
        let clock = FixedClock(now: Date(timeIntervalSince1970: 1_800_000_000))
        let monitor = AgentStatusMonitor(
            providers: [
                StubProvider(id: "codex", state: .idle),
                StubProvider(id: "claude", state: .working)
            ],
            clock: clock
        )

        let report = await monitor.collectOnce()

        #expect(report.overallState == .working)
        #expect(report.snapshots.map(\.agentID) == ["claude", "codex"])
        #expect(report.collectedAt == clock.now)
    }

    @Test
    func testCollectOnceWithNoProvidersReturnsUnknownReport() async {
        let monitor = AgentStatusMonitor(providers: [])

        let report = await monitor.collectOnce()

        #expect(report.overallState == .unknown)
        #expect(report.snapshots.isEmpty)
    }
}

private struct StubProvider: AgentStatusProvider {
    let id: String
    let state: AgentState

    var displayName: String {
        id
    }

    func snapshot() async -> AgentSnapshot {
        AgentSnapshot(
            agentID: id,
            displayName: displayName,
            state: state,
            confidence: 1,
            source: "stub"
        )
    }
}

private struct FixedClock: ClockProvider {
    let now: Date
}
