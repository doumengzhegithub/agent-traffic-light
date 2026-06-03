import Foundation

struct CodexProcessSignal: Equatable, Sendable {
    let hasCodexProcess: Bool
    let matchedCommands: [String]
}

struct CodexLogSignal: Equatable, Sendable {
    let activities: [FileActivity]
    let recentActivityAt: Date?
    let hasRecentActivity: Bool
    let pendingApprovalRequestedAt: Date?
}

struct CodexRuntimeSignal: Equatable, Sendable {
    let process: CodexProcessSignal
    let log: CodexLogSignal
    let observedAt: Date
    let processScanFailed: String?
    let waitingForUserHint: Bool
    let terminalFrontmost: Bool
}
