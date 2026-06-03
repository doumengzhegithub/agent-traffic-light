import Foundation

struct AgentSnapshot: Equatable, Sendable {
    let agentID: String
    let displayName: String
    let state: AgentState
    let confidence: Double
    let source: String
    let lastActivityAt: Date?
    let detail: String?

    init(
        agentID: String,
        displayName: String,
        state: AgentState,
        confidence: Double,
        source: String,
        lastActivityAt: Date? = nil,
        detail: String? = nil
    ) {
        self.agentID = agentID
        self.displayName = displayName
        self.state = state
        self.confidence = confidence
        self.source = source
        self.lastActivityAt = lastActivityAt
        self.detail = detail
    }
}
