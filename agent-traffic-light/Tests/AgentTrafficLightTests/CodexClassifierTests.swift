import Foundation
import Testing
@testable import AgentTrafficLight

struct CodexClassifierTests {
    private let classifier = CodexClassifier()
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func testProcessScanFailureFallsBackToIdle() {
        let classification = classifier.classify(signal(processScanFailed: "ps failed"))

        #expect(classification.state == .idle)
        #expect(classification.source == "process-scan-failed-idle-fallback")
    }

    @Test
    func testProcessScanFailureWithFrontmostTerminalReturnsWaiting() {
        let classification = classifier.classify(signal(
            processScanFailed: "ps failed",
            terminalFrontmost: true
        ))

        #expect(classification.state == .waitingForUser)
        #expect(classification.source == "terminal-waiting-process-scan-failed")
    }

    @Test
    func testRecentActivityBeatsTerminalProcessScanFailure() {
        let classification = classifier.classify(signal(
            hasRecentActivity: true,
            processScanFailed: "ps failed",
            terminalFrontmost: true
        ))

        #expect(classification.state == .working)
        #expect(classification.source == "codex-file-activity")
    }

    @Test
    func testWaitingHintHasPriority() {
        let classification = classifier.classify(signal(
            hasRecentActivity: true,
            waitingForUserHint: true
        ))

        #expect(classification.state == .waitingForUser)
    }

    @Test
    func testPendingApprovalHasPriorityOverWorking() {
        let classification = classifier.classify(signal(
            hasRecentActivity: true,
            pendingApprovalRequestedAt: now
        ))

        #expect(classification.state == .waitingForUser)
        #expect(classification.source == "codex-pending-approval")
        #expect(classification.lastActivityAt == now)
    }

    @Test
    func testRecentActivityReturnsWorking() {
        let classification = classifier.classify(signal(hasRecentActivity: true))

        #expect(classification.state == .working)
        #expect(classification.lastActivityAt == now)
    }

    @Test
    func testCodexCLIProcessWithoutActivityReturnsWaitingForUser() {
        let classification = classifier.classify(signal(
            matchedCommands: ["node /usr/local/bin/codex"]
        ))

        #expect(classification.state == .waitingForUser)
        #expect(classification.source == "codex-cli-waiting")
    }

    @Test
    func testCodexAppProcessWithoutActivityReturnsIdle() {
        let classification = classifier.classify(signal(
            matchedCommands: ["/Applications/Codex.app/Contents/MacOS/Codex"]
        ))

        #expect(classification.state == .idle)
        #expect(classification.source == "codex-process")
    }

    private func signal(
        hasCodexProcess: Bool = false,
        hasRecentActivity: Bool = false,
        processScanFailed: String? = nil,
        waitingForUserHint: Bool = false,
        matchedCommands: [String] = [],
        terminalFrontmost: Bool = false,
        pendingApprovalRequestedAt: Date? = nil
    ) -> CodexRuntimeSignal {
        let commands = matchedCommands.isEmpty && hasCodexProcess ? ["codex"] : matchedCommands

        return CodexRuntimeSignal(
            process: CodexProcessSignal(
                hasCodexProcess: hasCodexProcess || !commands.isEmpty,
                matchedCommands: commands
            ),
            log: CodexLogSignal(
                activities: [],
                recentActivityAt: hasRecentActivity ? now : nil,
                hasRecentActivity: hasRecentActivity,
                pendingApprovalRequestedAt: pendingApprovalRequestedAt
            ),
            observedAt: now,
            processScanFailed: processScanFailed,
            waitingForUserHint: waitingForUserHint,
            terminalFrontmost: terminalFrontmost
        )
    }
}
