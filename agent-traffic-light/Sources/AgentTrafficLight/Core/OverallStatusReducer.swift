struct OverallStatusReducer: Sendable {
    func reduce(_ snapshots: [AgentSnapshot]) -> AgentState {
        guard !snapshots.isEmpty else {
            return .unknown
        }

        let states = snapshots.map(\.state)

        if states.contains(.waitingForUser) {
            return .waitingForUser
        }

        if states.contains(.working) {
            return .working
        }

        if states.contains(.error) {
            return .error
        }

        if states.contains(.unknown) {
            return .unknown
        }

        return .idle
    }
}
