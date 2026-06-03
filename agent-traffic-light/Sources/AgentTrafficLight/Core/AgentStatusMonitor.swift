import Foundation

struct AgentStatusMonitor: Sendable {
    private let providers: [any AgentStatusProvider]
    private let reducer: OverallStatusReducer
    private let clock: ClockProvider

    init(
        providers: [any AgentStatusProvider],
        reducer: OverallStatusReducer = OverallStatusReducer(),
        clock: ClockProvider = SystemClock()
    ) {
        self.providers = providers
        self.reducer = reducer
        self.clock = clock
    }

    func collectOnce() async -> AgentStatusReport {
        let snapshots = await withTaskGroup(of: AgentSnapshot.self) { group in
            for provider in providers {
                group.addTask {
                    await provider.snapshot()
                }
            }

            var collected: [AgentSnapshot] = []
            for await snapshot in group {
                collected.append(snapshot)
            }

            return collected.sorted { $0.agentID < $1.agentID }
        }

        return AgentStatusReport(
            overallState: reducer.reduce(snapshots),
            snapshots: snapshots,
            collectedAt: clock.now
        )
    }
}
