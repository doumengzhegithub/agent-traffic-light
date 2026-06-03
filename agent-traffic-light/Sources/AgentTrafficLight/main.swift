import Foundation

let report = AgentStatusReport(
    overallState: .unknown,
    snapshots: [],
    collectedAt: Date()
)

print("AgentTrafficLight core initialized: \(report.overallState.rawValue)")
