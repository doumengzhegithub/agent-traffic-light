import Testing
@testable import AgentTrafficLight

struct CodexProcessProbeTests {
    @Test
    func testMatchesCodexProcessPatterns() {
        let signal = CodexProcessProbe.signal(from: [
            RunningProcess(pid: 1, command: "/sbin/launchd"),
            RunningProcess(pid: 2, command: "node /usr/local/bin/codex"),
            RunningProcess(pid: 3, command: "/Applications/Codex.app/Contents/Resources/codex app-server --listen stdio://"),
            RunningProcess(pid: 4, command: "/Applications/Codex.app/Contents/Resources/node_repl"),
            RunningProcess(pid: 5, command: "/Applications/Codex.app/Contents/MacOS/Codex")
        ])

        #expect(signal.hasCodexProcess)
        #expect(signal.matchedCommands.count == 4)
    }

    @Test
    func testReturnsFalseWhenNoCodexProcessExists() {
        let signal = CodexProcessProbe.signal(from: [
            RunningProcess(pid: 1, command: "/sbin/launchd"),
            RunningProcess(pid: 2, command: "/usr/bin/swift test")
        ])

        #expect(!signal.hasCodexProcess)
        #expect(signal.matchedCommands.isEmpty)
    }
}
