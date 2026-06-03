import Foundation

struct CodexLogProbe: Sendable {
    private let scanner: FileActivityScanner
    private let paths: [String]
    private let recentActivityWindow: TimeInterval
    private let clock: any ClockProvider
    private let commandRunner: any ShellCommandRunning
    private let logsDatabasePath: String

    init(
        scanner: FileActivityScanner = FileActivityScanner(),
        paths: [String] = Self.defaultPaths(),
        recentActivityWindow: TimeInterval = 6,
        clock: any ClockProvider = SystemClock(),
        commandRunner: any ShellCommandRunning = ShellCommand(),
        logsDatabasePath: String = Self.defaultLogsDatabasePath()
    ) {
        self.scanner = scanner
        self.paths = paths
        self.recentActivityWindow = recentActivityWindow
        self.clock = clock
        self.commandRunner = commandRunner
        self.logsDatabasePath = logsDatabasePath
    }

    func signal() async -> CodexLogSignal {
        let activities = scanner.activity(for: paths)
        let pendingApprovalRequestedAt = await pendingApprovalRequestedAt()
        let recentLogEventAt = await recentRuntimeLogEventAt()
        let recentHistoryActivityAt = activities
            .filter(Self.isHistoryActivity)
            .compactMap(\.modifiedAt)
            .max()
        let recentActivityAt = [recentLogEventAt, recentHistoryActivityAt]
            .compactMap { $0 }
            .max()

        let hasRecentActivity = recentActivityAt.map {
            clock.now.timeIntervalSince($0) <= recentActivityWindow
        } ?? false

        return CodexLogSignal(
            activities: activities,
            recentActivityAt: recentActivityAt,
            hasRecentActivity: hasRecentActivity,
            pendingApprovalRequestedAt: pendingApprovalRequestedAt
        )
    }

    private func pendingApprovalRequestedAt() async -> Date? {
        guard FileManager.default.fileExists(atPath: logsDatabasePath) else {
            return nil
        }

        let earliestTimestamp = Int(clock.now.timeIntervalSince1970 - 600)
        let query = """
        with request as (
            select max(ts) as ts from logs
            where ts >= \(earliestTimestamp)
              and target = 'codex_core::stream_events_utils'
              and feedback_log_body like '%ToolCall:%'
              and feedback_log_body like '%sandbox_permissions%'
              and feedback_log_body like '%require_escalated%'
              and feedback_log_body not like '%sqlite3 %'
        ),
        decision as (
            select max(ts) as ts from logs
            where ts >= \(earliestTimestamp)
              and target = 'codex_otel.log_only'
              and (
                feedback_log_body like '%event.name="codex.tool_decision"%'
                or feedback_log_body like '%ExecApproval%'
              )
        )
        select request.ts from request, decision
        where request.ts is not null
          and (decision.ts is null or decision.ts < request.ts);
        """

        do {
            let result = try await commandRunner.run(
                executablePath: "/usr/bin/sqlite3",
                arguments: [logsDatabasePath, query],
                timeout: 1
            )

            guard
                result.exitCode == 0,
                let timestamp = TimeInterval(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines))
            else {
                return nil
            }

            return Date(timeIntervalSince1970: timestamp)
        } catch {
            return nil
        }
    }

    private func recentRuntimeLogEventAt() async -> Date? {
        guard FileManager.default.fileExists(atPath: logsDatabasePath) else {
            return nil
        }

        let earliestTimestamp = Int(clock.now.timeIntervalSince1970 - recentActivityWindow)
        let query = """
        select max(ts) from logs
        where ts >= \(earliestTimestamp)
          and (
            target like 'codex_api::%'
            or target like 'codex_core::stream_events_utils%'
            or target like 'codex_tui::streaming%'
            or target = 'codex_otel.trace_safe'
            or target = 'codex_otel.log_only'
            or feedback_log_body like '%response.output_item.added%'
            or feedback_log_body like '%response.output_text.delta%'
            or feedback_log_body like '%response.function_call_arguments.delta%'
          );
        """

        do {
            let result = try await commandRunner.run(
                executablePath: "/usr/bin/sqlite3",
                arguments: [logsDatabasePath, query],
                timeout: 1
            )

            guard
                result.exitCode == 0,
                let timestamp = TimeInterval(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines))
            else {
                return nil
            }

            return Date(timeIntervalSince1970: timestamp)
        } catch {
            return nil
        }
    }

    private static func isHistoryActivity(_ activity: FileActivity) -> Bool {
        activity.path.hasSuffix("/.codex/history.jsonl")
    }

    static func defaultPaths(homeDirectory: String? = nil) -> [String] {
        let home = homeDirectory
            ?? ProcessInfo.processInfo.environment["HOME"]
            ?? NSHomeDirectory()

        return [
            ".codex/logs_2.sqlite",
            ".codex/logs_2.sqlite-wal",
            ".codex/state_5.sqlite",
            ".codex/state_5.sqlite-wal",
            ".codex/history.jsonl",
            ".codex/session_index.jsonl"
        ].map { "\(home)/\($0)" }
    }

    static func defaultLogsDatabasePath(homeDirectory: String? = nil) -> String {
        let home = homeDirectory
            ?? ProcessInfo.processInfo.environment["HOME"]
            ?? NSHomeDirectory()

        return "\(home)/.codex/logs_2.sqlite"
    }
}
