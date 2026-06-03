# AgentTrafficLight

macOS floating traffic light for AI agent status.

This Swift package currently contains the first implementation slice:

- Core agent state model
- Agent snapshot/report model
- Provider protocol
- Overall status reducer
- One-shot status monitor
- System process and file activity scanners
- First Codex provider based on process and `.codex` file activity
- First macOS floating traffic light prototype
- Unit tests for core, system, and Codex classifier behavior

The first prototype shows a small traffic light that follows the active Codex CLI terminal window:

- Red: recent Codex runtime log activity, treated as working
- Yellow: Codex CLI is active and waiting for user input, command approval, or another action
- Green: Codex appears idle, or no Codex activity is detected
- Gray/unknown: probe failure or uncertain status

Command approval is detected from recent `~/.codex/logs_2.sqlite` tool-call events where an escalated command request is newer than the latest approval decision. When terminal title access or process scanning is restricted, the prototype falls back to yellow while the terminal is frontmost and there is no recent Codex runtime activity. This avoids showing green during approval prompts.

The light is placed near the top-left corner of the active terminal window. It hides automatically when the active app is not a supported terminal app.

Right-click the light for Refresh, Copy Status, Reposition, and Quit. Copy Status writes the current provider state, source, confidence, and last activity timestamp to the clipboard.

## Commands

```bash
make test
make build
make run
make run-built
make run-tty
make start
make stop
make status
make logs
```

`make run-built` builds first, then launches the compiled executable directly. This is useful in restricted environments where `swift run` cannot use SwiftPM's user-level caches.

`make run-tty` launches the compiled executable through `script(1)` so the process has a TTY-backed session while the prototype runs.

`make start` launches AgentTrafficLight as a user `launchctl` service using label `com.littlehld.agent-traffic-light`. It writes the generated plist to `/tmp/agent-traffic-light.plist`, records the current PID in `/tmp/agent-traffic-light.pid` when available, and logs to `/tmp/agent-traffic-light.log`.

Use `make stop` to stop the background process, `make status` to check it, and `make logs` to follow logs.

If `swift test` fails with an SDK/compiler mismatch, reinstall or update Xcode Command Line Tools. The current source tree is intentionally small so the toolchain issue is easy to separate from application code.
