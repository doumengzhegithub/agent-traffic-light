import Foundation

struct ShellCommandResult: Equatable, Sendable {
    let exitCode: Int32
    let stdout: String
    let stderr: String
}

protocol ShellCommandRunning: Sendable {
    func run(
        executablePath: String,
        arguments: [String],
        timeout: TimeInterval
    ) async throws -> ShellCommandResult
}

enum ShellCommandError: Error, Equatable, Sendable {
    case launchFailed(String)
    case timedOut
}

struct ShellCommand: ShellCommandRunning {
    func run(
        executablePath: String,
        arguments: [String] = [],
        timeout: TimeInterval = 2
    ) async throws -> ShellCommandResult {
        try await Task.detached(priority: .utility) {
            try runSynchronously(
                executablePath: executablePath,
                arguments: arguments,
                timeout: timeout
            )
        }.value
    }
}

private func runSynchronously(
    executablePath: String,
    arguments: [String],
    timeout: TimeInterval
) throws -> ShellCommandResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executablePath)
    process.arguments = arguments

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    do {
        try process.run()
    } catch {
        throw ShellCommandError.launchFailed(error.localizedDescription)
    }

    let deadline = Date().addingTimeInterval(timeout)
    while process.isRunning {
        if Date() >= deadline {
            process.terminate()
            process.waitUntilExit()
            throw ShellCommandError.timedOut
        }

        Thread.sleep(forTimeInterval: 0.01)
    }

    let stdout = String(
        data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
        encoding: .utf8
    ) ?? ""
    let stderr = String(
        data: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
        encoding: .utf8
    ) ?? ""

    return ShellCommandResult(
        exitCode: process.terminationStatus,
        stdout: stdout,
        stderr: stderr
    )
}
