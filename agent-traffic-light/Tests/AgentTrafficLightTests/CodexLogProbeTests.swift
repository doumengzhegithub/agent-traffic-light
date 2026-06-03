import Foundation
import Testing
@testable import AgentTrafficLight

struct CodexLogProbeTests {
    @Test
    func testIgnoresWalAndStateFilesForWorkingActivity() async throws {
        let clock = FixedClock(now: Date(timeIntervalSince1970: 1_800_000_000))
        let directory = try makeTemporaryCodexDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let stateWal = directory.appendingPathComponent("state_5.sqlite-wal")
        let logsWal = directory.appendingPathComponent("logs_2.sqlite-wal")
        try writeFile(stateWal, modifiedAt: clock.now)
        try writeFile(logsWal, modifiedAt: clock.now)

        let probe = CodexLogProbe(
            paths: [stateWal.path, logsWal.path],
            recentActivityWindow: 3,
            clock: clock,
            commandRunner: StubCommandRunner(outputs: ["", ""]),
            logsDatabasePath: directory.appendingPathComponent("logs_2.sqlite").path
        )

        let signal = await probe.signal()

        #expect(!signal.hasRecentActivity)
        #expect(signal.recentActivityAt == nil)
    }

    @Test
    func testRecentHistoryFileActivityReturnsWorkingSignal() async throws {
        let clock = FixedClock(now: Date(timeIntervalSince1970: 1_800_000_000))
        let directory = try makeTemporaryCodexDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let history = directory.appendingPathComponent("history.jsonl")
        try writeFile(history, modifiedAt: clock.now.addingTimeInterval(-2))

        let probe = CodexLogProbe(
            paths: [history.path],
            recentActivityWindow: 3,
            clock: clock,
            commandRunner: StubCommandRunner(outputs: ["", ""]),
            logsDatabasePath: directory.appendingPathComponent("logs_2.sqlite").path
        )

        let signal = await probe.signal()

        #expect(signal.hasRecentActivity)
        #expect(signal.recentActivityAt == clock.now.addingTimeInterval(-2))
    }

    @Test
    func testRecentRuntimeLogEventReturnsWorkingSignal() async throws {
        let clock = FixedClock(now: Date(timeIntervalSince1970: 1_800_000_000))
        let directory = try makeTemporaryCodexDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let database = directory.appendingPathComponent("logs_2.sqlite")
        try writeFile(database, modifiedAt: clock.now.addingTimeInterval(-100))

        let probe = CodexLogProbe(
            paths: [],
            recentActivityWindow: 6,
            clock: clock,
            commandRunner: StubCommandRunner(outputs: ["", "1800000000\n"]),
            logsDatabasePath: database.path
        )

        let signal = await probe.signal()

        #expect(signal.hasRecentActivity)
        #expect(signal.recentActivityAt == clock.now)
    }

    @Test
    func testPendingApprovalReturnsWaitingSignal() async throws {
        let clock = FixedClock(now: Date(timeIntervalSince1970: 1_800_000_000))
        let directory = try makeTemporaryCodexDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let database = directory.appendingPathComponent("logs_2.sqlite")
        try writeFile(database, modifiedAt: clock.now)

        let probe = CodexLogProbe(
            paths: [],
            recentActivityWindow: 6,
            clock: clock,
            commandRunner: StubCommandRunner(outputs: ["1800000000\n", ""]),
            logsDatabasePath: database.path
        )

        let signal = await probe.signal()

        #expect(signal.pendingApprovalRequestedAt == clock.now)
    }

    private func makeTemporaryCodexDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent(".codex")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func writeFile(_ url: URL, modifiedAt: Date) throws {
        try "x".write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.modificationDate: modifiedAt],
            ofItemAtPath: url.path
        )
    }
}

private struct FixedClock: ClockProvider {
    let now: Date
}

private actor StubCommandRunner: ShellCommandRunning {
    private var outputs: [String]

    init(outputs: [String]) {
        self.outputs = outputs
    }

    func run(
        executablePath: String,
        arguments: [String],
        timeout: TimeInterval
    ) async throws -> ShellCommandResult {
        let stdout = outputs.isEmpty ? "" : outputs.removeFirst()
        return ShellCommandResult(exitCode: 0, stdout: stdout, stderr: "")
    }
}
