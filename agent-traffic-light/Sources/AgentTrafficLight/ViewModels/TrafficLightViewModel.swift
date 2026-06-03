import Foundation

@MainActor
final class TrafficLightViewModel: ObservableObject {
    @Published private(set) var report = AgentStatusReport(
        overallState: .unknown,
        snapshots: [],
        collectedAt: Date()
    )

    private let monitor: AgentStatusMonitor
    private let pollInterval: Duration
    private var pollingTask: Task<Void, Never>?

    init(
        monitor: AgentStatusMonitor,
        pollInterval: Duration = .seconds(1)
    ) {
        self.monitor = monitor
        self.pollInterval = pollInterval
    }

    var overallState: AgentState {
        report.overallState
    }

    var statusTitle: String {
        switch report.overallState {
        case .working:
            return "Working"
        case .waitingForUser:
            return "Waiting"
        case .idle:
            return "Idle"
        case .error:
            return "Error"
        case .unknown:
            return "Unknown"
        }
    }

    var statusDetail: String {
        guard let snapshot = report.snapshots.first else {
            return "No providers"
        }

        return snapshot.detail ?? snapshot.source
    }

    var debugStatusText: String {
        var lines = [
            "Agent Traffic Light",
            "overallState: \(report.overallState.rawValue)",
            "collectedAt: \(Self.format(report.collectedAt))"
        ]

        if report.snapshots.isEmpty {
            lines.append("providers: none")
        } else {
            for snapshot in report.snapshots {
                lines.append("")
                lines.append("provider: \(snapshot.displayName) (\(snapshot.agentID))")
                lines.append("state: \(snapshot.state.rawValue)")
                lines.append("confidence: \(snapshot.confidence)")
                lines.append("source: \(snapshot.source)")

                if let lastActivityAt = snapshot.lastActivityAt {
                    lines.append("lastActivityAt: \(Self.format(lastActivityAt))")
                }

                if let detail = snapshot.detail {
                    lines.append("detail: \(detail)")
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    func start() {
        guard pollingTask == nil else {
            return
        }

        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: self?.pollInterval ?? .seconds(1))
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func refresh() async {
        report = await monitor.collectOnce()
    }

    private static func format(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
