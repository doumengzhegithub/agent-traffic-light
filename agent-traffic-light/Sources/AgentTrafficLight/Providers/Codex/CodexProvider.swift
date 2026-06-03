import Foundation

struct CodexProvider: AgentStatusProvider {
    let id = "codex"
    let displayName = "Codex"

    private let processProbe: CodexProcessProbe
    private let logProbe: CodexLogProbe
    private let attentionProbe: CodexAttentionProbe
    private let classifier: CodexClassifier
    private let clock: any ClockProvider

    init(
        processProbe: CodexProcessProbe = CodexProcessProbe(),
        logProbe: CodexLogProbe = CodexLogProbe(),
        attentionProbe: CodexAttentionProbe = CodexAttentionProbe(),
        classifier: CodexClassifier = CodexClassifier(),
        clock: any ClockProvider = SystemClock()
    ) {
        self.processProbe = processProbe
        self.logProbe = logProbe
        self.attentionProbe = attentionProbe
        self.classifier = classifier
        self.clock = clock
    }

    func snapshot() async -> AgentSnapshot {
        let processSignal: CodexProcessSignal
        let processScanFailed: String?

        do {
            processSignal = try await processProbe.signal()
            processScanFailed = nil
        } catch {
            let fallbackSignal = await CodexProcessProbe.signalFromRunningApplications()
            processSignal = fallbackSignal
            processScanFailed = fallbackSignal.hasCodexProcess ? nil : String(describing: error)
        }

        let signal = CodexRuntimeSignal(
            process: processSignal,
            log: await logProbe.signal(),
            observedAt: clock.now,
            processScanFailed: processScanFailed,
            waitingForUserHint: await attentionProbe.needsAttention(),
            terminalFrontmost: await attentionProbe.isTerminalFrontmost()
        )
        let classification = classifier.classify(signal)

        return AgentSnapshot(
            agentID: id,
            displayName: displayName,
            state: classification.state,
            confidence: classification.confidence,
            source: classification.source,
            lastActivityAt: classification.lastActivityAt,
            detail: classification.detail
        )
    }
}
