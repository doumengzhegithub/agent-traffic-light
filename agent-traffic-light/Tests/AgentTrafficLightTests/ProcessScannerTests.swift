import Foundation
import Testing
@testable import AgentTrafficLight

struct ProcessScannerTests {
    @Test
    func testParsePSOutputKeepsCommandsWithSpaces() {
        let output = """
          PID COMMAND
            1 /sbin/launchd
          123 /Applications/Codex.app/Contents/MacOS/Codex --flag value
          bad not-a-process
        """

        let processes = ProcessScanner.parsePSOutput(output)

        #expect(processes == [
            RunningProcess(pid: 1, command: "/sbin/launchd"),
            RunningProcess(pid: 123, command: "/Applications/Codex.app/Contents/MacOS/Codex --flag value")
        ])
    }

    @Test
    func testRunningProcessesUsesPSCommand() async throws {
        let runner = StubCommandRunner(result: ShellCommandResult(
            exitCode: 0,
            stdout: "  PID COMMAND\n  42 codex\n",
            stderr: ""
        ))
        let scanner = ProcessScanner(commandRunner: runner, timeout: 5)

        let processes = try await scanner.runningProcesses()

        #expect(processes == [RunningProcess(pid: 42, command: "codex")])
        #expect(await runner.calls == [
            CommandCall(
                executablePath: "/bin/ps",
                arguments: ["-axo", "pid,command"],
                timeout: 5
            )
        ])
    }

    @Test
    func testRunningProcessesThrowsWhenPSFails() async {
        let runner = StubCommandRunner(result: ShellCommandResult(
            exitCode: 1,
            stdout: "",
            stderr: "permission denied"
        ))
        let scanner = ProcessScanner(commandRunner: runner)

        await #expect(throws: ProcessScannerError.commandFailed(
            exitCode: 1,
            stderr: "permission denied"
        )) {
            try await scanner.runningProcesses()
        }
    }
}

private struct CommandCall: Equatable {
    let executablePath: String
    let arguments: [String]
    let timeout: TimeInterval
}

private actor StubCommandRunner: ShellCommandRunning {
    private let result: ShellCommandResult
    private(set) var calls: [CommandCall] = []

    init(result: ShellCommandResult) {
        self.result = result
    }

    func run(
        executablePath: String,
        arguments: [String],
        timeout: TimeInterval
    ) async throws -> ShellCommandResult {
        calls.append(CommandCall(
            executablePath: executablePath,
            arguments: arguments,
            timeout: timeout
        ))
        return result
    }
}
