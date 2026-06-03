enum AgentState: String, CaseIterable, Equatable, Sendable {
    case idle
    case working
    case waitingForUser
    case error
    case unknown
}
