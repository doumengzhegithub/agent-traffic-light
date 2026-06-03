import Foundation

struct CodexClassification: Equatable, Sendable {
    let state: AgentState
    let confidence: Double
    let source: String
    let detail: String?
    let lastActivityAt: Date?
}

struct CodexClassifier: Sendable {
    func classify(_ signal: CodexRuntimeSignal) -> CodexClassification {
        if signal.waitingForUserHint {
            return CodexClassification(
                state: .waitingForUser,
                confidence: 0.8,
                source: "codex-waiting-hint",
                detail: "Codex appears to be waiting for user input.",
                lastActivityAt: signal.log.recentActivityAt
            )
        }

        if let pendingApprovalRequestedAt = signal.log.pendingApprovalRequestedAt {
            return CodexClassification(
                state: .waitingForUser,
                confidence: 0.9,
                source: "codex-pending-approval",
                detail: "Codex is waiting for command approval.",
                lastActivityAt: pendingApprovalRequestedAt
            )
        }

        if signal.log.hasRecentActivity {
            return CodexClassification(
                state: .working,
                confidence: 0.65,
                source: "codex-file-activity",
                detail: "Recent activity in .codex state files.",
                lastActivityAt: signal.log.recentActivityAt
            )
        }

        if let processScanFailed = signal.processScanFailed, signal.terminalFrontmost {
            return CodexClassification(
                state: .waitingForUser,
                confidence: 0.45,
                source: "terminal-waiting-process-scan-failed",
                detail: "Terminal is active and no recent runtime activity was detected. Process scan failed: \(processScanFailed)",
                lastActivityAt: signal.log.recentActivityAt
            )
        }

        if let processScanFailed = signal.processScanFailed {
            return CodexClassification(
                state: .idle,
                confidence: 0.35,
                source: "process-scan-failed-idle-fallback",
                detail: "Process scan failed; falling back to idle. \(processScanFailed)",
                lastActivityAt: signal.log.recentActivityAt
            )
        }

        if signal.process.hasCodexCLIProcess {
            return CodexClassification(
                state: .waitingForUser,
                confidence: 0.7,
                source: "codex-cli-waiting",
                detail: "Codex CLI is active and no recent runtime activity was detected.",
                lastActivityAt: signal.log.recentActivityAt
            )
        }

        if signal.process.hasCodexProcess {
            return CodexClassification(
                state: .idle,
                confidence: 0.7,
                source: "codex-process",
                detail: "Codex process is running.",
                lastActivityAt: signal.log.recentActivityAt
            )
        }

        return CodexClassification(
            state: .idle,
            confidence: 0.6,
            source: "codex-no-activity",
            detail: "No Codex process or recent file activity detected.",
            lastActivityAt: signal.log.recentActivityAt
        )
    }
}

private extension CodexProcessSignal {
    var hasCodexCLIProcess: Bool {
        matchedCommands.contains { command in
            let lowercased = command.lowercased()

            return lowercased.contains("@openai/codex")
                || lowercased.contains("/bin/codex")
                || lowercased.contains("/usr/local/bin/codex")
                || lowercased.contains("node /usr/local/bin/codex")
        }
    }
}
