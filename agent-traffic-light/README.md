# AgentTrafficLight

macOS floating traffic light for AI agent status.

This Swift package currently contains the first implementation slice:

- Core agent state model
- Agent snapshot/report model
- Provider protocol
- Overall status reducer
- One-shot status monitor
- Unit tests for reducer and monitor behavior

The AppKit/SwiftUI floating window and Codex provider will be added in later slices.

## Commands

```bash
make test
make build
make run
```

If `swift test` fails with an SDK/compiler mismatch, reinstall or update Xcode Command Line Tools. The current source tree is intentionally small so the toolchain issue is easy to separate from application code.
