import Foundation

struct AgentStatusReport: Equatable, Sendable {
    let overallState: AgentState
    let snapshots: [AgentSnapshot]
    let collectedAt: Date
}
