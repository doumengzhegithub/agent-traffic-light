import AppKit
import Foundation

struct CodexProcessProbe: Sendable {
    private let scanner: ProcessScanner

    init(scanner: ProcessScanner = ProcessScanner()) {
        self.scanner = scanner
    }

    func signal() async throws -> CodexProcessSignal {
        let processes = try await scanner.runningProcesses()
        return Self.signal(from: processes)
    }

    @MainActor
    static func signalFromRunningApplications() -> CodexProcessSignal {
        let commands = NSWorkspace.shared.runningApplications
            .compactMap { application -> String? in
                let bundleIdentifier = application.bundleIdentifier ?? ""
                let localizedName = application.localizedName ?? ""
                let bundlePath = application.bundleURL?.path ?? ""
                let candidate = "\(bundleIdentifier) \(localizedName) \(bundlePath)"

                guard isCodexCommand(candidate) else {
                    return nil
                }

                return candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            }

        return CodexProcessSignal(
            hasCodexProcess: !commands.isEmpty,
            matchedCommands: commands.sorted()
        )
    }

    static func signal(from processes: [RunningProcess]) -> CodexProcessSignal {
        let commands = processes
            .map(\.command)
            .filter(isCodexCommand)

        return CodexProcessSignal(
            hasCodexProcess: !commands.isEmpty,
            matchedCommands: commands.sorted()
        )
    }

    private static func isCodexCommand(_ command: String) -> Bool {
        let lowercased = command.lowercased()

        return lowercased.contains("/codex.app/")
            || lowercased.contains("com.openai.codex")
            || lowercased.contains(" codex.app")
            || lowercased.contains("@openai/codex")
            || lowercased.contains(" codex")
            || lowercased.hasSuffix("/codex")
            || lowercased.hasSuffix(" codex")
            || lowercased.contains("codex app-server")
            || lowercased.contains("node_repl")
    }
}
