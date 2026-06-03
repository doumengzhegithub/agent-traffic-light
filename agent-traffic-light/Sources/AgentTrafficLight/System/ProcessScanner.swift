import Foundation

struct RunningProcess: Equatable, Sendable {
    let pid: Int32
    let command: String
}

enum ProcessScannerError: Error, Equatable, Sendable {
    case commandFailed(exitCode: Int32, stderr: String)
}

struct ProcessScanner: Sendable {
    private let commandRunner: any ShellCommandRunning
    private let timeout: TimeInterval

    init(
        commandRunner: any ShellCommandRunning = ShellCommand(),
        timeout: TimeInterval = 2
    ) {
        self.commandRunner = commandRunner
        self.timeout = timeout
    }

    func runningProcesses() async throws -> [RunningProcess] {
        let result = try await commandRunner.run(
            executablePath: "/bin/ps",
            arguments: ["-axo", "pid,command"],
            timeout: timeout
        )

        guard result.exitCode == 0 else {
            throw ProcessScannerError.commandFailed(
                exitCode: result.exitCode,
                stderr: result.stderr
            )
        }

        return Self.parsePSOutput(result.stdout)
    }

    static func parsePSOutput(_ output: String) -> [RunningProcess] {
        output
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> RunningProcess? in
                let parts = line.split(
                    maxSplits: 1,
                    omittingEmptySubsequences: true,
                    whereSeparator: \.isWhitespace
                )

                guard
                    parts.count == 2,
                    let pid = Int32(parts[0])
                else {
                    return nil
                }

                return RunningProcess(pid: pid, command: String(parts[1]))
            }
    }
}
