# Agent Traffic Light 方案文档

> 本文档只描述方案、架构和后续开发计划，不包含真实应用代码。
> 未来真实代码建议放在独立目录 `agent-traffic-light/` 下，避免和方案文档混在一起。

## 1. 目标

做一个适用于 macOS 的 AI Agent 状态悬浮挂件，视觉形态类似桌面上的小交通灯。

第一版先支持 Codex CLI / Codex App 的状态判断，后续扩展到多个 Agent，例如 Claude Code、Cursor、Aider、自定义脚本 Agent 等。

状态含义：

| 灯 | 状态 | 含义 |
| --- | --- | --- |
| 红灯 | working | Agent 正在生成、执行命令、跑工具或处理任务 |
| 黄灯 | waitingForUser | Agent 正在等待用户输入、选择、确认或授权 |
| 绿灯 | idle | Agent 空闲，或没有活跃任务 |
| 灰灯 | unknown | 状态无法可靠判断 |
| 红/黄附加态 | error | 后续可用于显示异常、探测失败或 Agent 报错 |

## 2. 产品形态

默认形态是一个小型 macOS 悬浮窗：

```text
┌─────┐
│ 🔴  │
│ 🟡  │
│ 🟢  │
└─────┘
```

核心能力：

- 始终置顶
- 透明背景
- 竖版三灯
- 可拖拽移动
- 自动记住位置
- 右键菜单
- 支持聚合多个 Agent 状态
- 点击或右键查看每个 Agent 的具体状态

第一版优先做小而稳的悬浮灯，不做复杂 dashboard。

## 3. 项目与代码位置

当前文档位置：

```text
/Users/doumengzhe/littleHLD/docs/agent-traffic-light-design.md
```

未来真实代码建议放在：

```text
/Users/doumengzhe/littleHLD/agent-traffic-light/
```

代码目录和文档目录分离：

```text
littleHLD/
├── docs/
│   └── agent-traffic-light-design.md
│
└── agent-traffic-light/
    ├── Package.swift
    ├── README.md
    ├── Sources/
    └── Tests/
```

原则：

- `docs/` 只放方案、设计、调研记录、使用说明。
- `agent-traffic-light/` 只放可编译、可运行的真实 Swift 项目。
- 后续不要把示例伪代码直接当作真实代码提交到 `Sources/`。

## 4. 技术选型

推荐使用：

```text
Swift + SwiftUI + AppKit
```

原因：

- 原生 macOS 悬浮窗能力最好。
- 资源占用低。
- 支持透明窗口、置顶窗口、拖拽、右键菜单。
- 后续可以打包成 `.app`。
- 可以加入开机启动、菜单栏入口等 macOS 原生能力。

当前机器环境已经满足第一版开发：

```text
Swift 6.0.3
Git 2.39.5
Xcode Command Line Tools
macOS target 14.0
```

暂时不强制依赖：

- 完整 Xcode
- Homebrew
- SwiftLint
- SwiftFormat
- fswatch

## 5. 架构原则

不要把系统写死成 Codex 单例。

第一版虽然只实现 Codex，但核心模型、UI 聚合和配置应该按多 Agent 设计。

关键原则：

- UI 不关心具体 Agent 如何探测状态。
- 每个 Agent 用独立 Provider 负责状态检测。
- 多个 Agent 的状态通过 Reducer 聚合成一个总状态。
- 状态探测逻辑和 UI 展示逻辑分离。
- 配置和代码分离，后续可启用/禁用不同 Provider。

## 6. 未来代码目录结构

建议真实 Swift 项目结构：

```text
agent-traffic-light/
├── Package.swift
├── README.md
├── Makefile
├── Sources/
│   └── AgentTrafficLight/
│       ├── App/
│       │   ├── AgentTrafficLightApp.swift
│       │   ├── AppDelegate.swift
│       │   └── MenuController.swift
│       │
│       ├── UI/
│       │   ├── FloatingPanel.swift
│       │   ├── TrafficLightView.swift
│       │   ├── TrafficLightDot.swift
│       │   ├── AgentListView.swift
│       │   ├── AgentRowView.swift
│       │   └── StatusPopoverView.swift
│       │
│       ├── Core/
│       │   ├── AgentState.swift
│       │   ├── AgentSnapshot.swift
│       │   ├── AgentStatusProvider.swift
│       │   ├── AgentStatusMonitor.swift
│       │   └── OverallStatusReducer.swift
│       │
│       ├── Providers/
│       │   ├── Codex/
│       │   │   ├── CodexProvider.swift
│       │   │   ├── CodexProcessProbe.swift
│       │   │   ├── CodexLogProbe.swift
│       │   │   └── CodexClassifier.swift
│       │   │
│       │   ├── ClaudeCode/
│       │   │   ├── ClaudeCodeProvider.swift
│       │   │   ├── ClaudeCodeProcessProbe.swift
│       │   │   └── ClaudeCodeClassifier.swift
│       │   │
│       │   └── Custom/
│       │       └── CustomScriptProvider.swift
│       │
│       ├── Config/
│       │   ├── AgentConfig.swift
│       │   ├── AppPreferences.swift
│       │   └── PositionStore.swift
│       │
│       └── System/
│           ├── ShellCommand.swift
│           ├── ProcessScanner.swift
│           └── FileActivityScanner.swift
│
└── Tests/
    └── AgentTrafficLightTests/
        ├── OverallStatusReducerTests.swift
        ├── CodexClassifierTests.swift
        └── CustomScriptProviderTests.swift
```

## 7. 核心模型

真实代码里建议使用通用 Agent 模型。

示意：

```swift
enum AgentState {
    case idle
    case working
    case waitingForUser
    case error
    case unknown
}

struct AgentSnapshot {
    let agentID: String
    let displayName: String
    let state: AgentState
    let confidence: Double
    let source: String
    let lastActivityAt: Date?
    let detail: String?
}
```

Provider 抽象：

```swift
protocol AgentStatusProvider {
    var id: String { get }
    var displayName: String { get }
    func snapshot() async -> AgentSnapshot
}
```

注意：上面是架构示意，不是当前要落地的真实代码。

## 8. 状态探测设计

### 8.1 CodexProvider

第一版 CodexProvider 可以组合多个 Probe：

```text
CodexProvider
├── CodexProcessProbe
├── CodexLogProbe
└── CodexClassifier
```

探测来源：

- `ps` / `pgrep` 检测 Codex CLI / Codex App 进程。
- 检查 `~/.codex` 目录下 session / log 文件。
- 通过文件最近修改时间判断是否有持续活动。
- 通过日志文本判断是否等待用户确认、选择、输入。

### 8.2 状态分类规则

第一版规则可以保守一些：

```text
如果检测到等待用户输入、确认、选择、授权
=> waitingForUser

否则如果检测到近期有工具调用、模型输出、命令执行、日志持续更新
=> working

否则如果 Codex 进程存在但近期没有活动
=> idle

否则如果没有 Codex 进程，也没有近期 session 活动
=> idle

否则
=> unknown
```

等待用户的关键词可以先从这些开始：

```text
approval
approve
confirm
continue
select
choose
waiting
permission
Do you want
Enter to
Submit
```

后续应根据本机 Codex 实际日志格式修正规则。

## 9. 多 Agent 聚合策略

多个 Agent 的快照由 `AgentStatusMonitor` 定期收集。

聚合规则由 `OverallStatusReducer` 负责。

建议优先级：

```text
waitingForUser > working > error > unknown > idle
```

含义：

- 只要有一个 Agent 等用户，就黄灯。
- 否则只要有一个 Agent 工作中，就红灯。
- 否则如果有异常，可以显示错误态。
- 全部空闲才绿灯。
- 状态不完整或无法判断时灰灯。

## 10. UI 设计

### 10.1 默认聚合灯

默认显示一个三色交通灯，代表所有 Agent 的聚合状态。

适合日常扫一眼：

```text
红：任意 Agent working
黄：任意 Agent waitingForUser
绿：全部 idle
灰：状态未知
```

### 10.2 展开列表

点击或右键可以显示 Agent 列表：

```text
┌────────────────┐
│ Codex       🔴 │
│ Claude Code 🟢 │
│ Cursor      🟡 │
└────────────────┘
```

第一版可以先不做复杂列表，只预留架构。

### 10.3 右键菜单

建议菜单项：

```text
显示/隐藏
重置位置
切换竖版/横版
调整大小
刷新状态
开机启动
退出
```

第一版至少实现：

```text
重置位置
刷新状态
退出
```

## 11. 配置设计

后续可以使用 JSON 或 plist 配置 Provider。

示意：

```json
{
  "pollIntervalSeconds": 1,
  "providers": [
    {
      "id": "codex",
      "enabled": true,
      "type": "codex",
      "displayName": "Codex"
    },
    {
      "id": "claude-code",
      "enabled": false,
      "type": "claudeCode",
      "displayName": "Claude Code"
    },
    {
      "id": "custom-build-agent",
      "enabled": false,
      "type": "customScript",
      "displayName": "Build Agent",
      "command": "/Users/doumengzhe/bin/check-agent-status"
    }
  ]
}
```

第一版可以先硬编码启用 CodexProvider，但保留 ProviderRegistry 和配置模型。

## 12. 自定义脚本 Agent

后续可以支持 `CustomScriptProvider`。

约定脚本输出 JSON：

```json
{
  "state": "working",
  "detail": "running tests",
  "lastActivityAt": "2026-05-27T10:30:00Z"
}
```

这样接入新 Agent 时不一定需要改 Swift 代码。

脚本状态枚举建议支持：

```text
idle
working
waitingForUser
error
unknown
```

## 13. 启动方式

开发期：

```bash
cd /Users/doumengzhe/littleHLD/agent-traffic-light
swift run AgentTrafficLight
```

后续可以增加 `Makefile`：

```bash
make run
make build
make test
make app
make install
```

含义：

| 命令 | 用途 |
| --- | --- |
| `make run` | 本地运行 |
| `make build` | 编译 |
| `make test` | 跑测试 |
| `make app` | 打包 `.app` |
| `make install` | 安装到 `~/Applications` |

## 14. 开发阶段规划

### 阶段 1：文档和骨架

- 固化方案文档。
- 创建真实 Swift Package。
- 搭好多 Agent 核心模型。
- 暂不追求状态判断准确性。

### 阶段 2：悬浮灯 MVP

- 实现透明置顶悬浮窗。
- 实现竖版三色灯 UI。
- 支持拖拽。
- 记住位置。
- 支持右键退出和重置位置。
- 支持手动模拟状态，验证 UI。

### 阶段 3：Codex 状态探测

- 实现 ProcessScanner。
- 实现 CodexProcessProbe。
- 调研 `~/.codex` 文件结构。
- 实现 CodexLogProbe。
- 实现 CodexClassifier。
- 状态接入真实红黄绿灯。

### 阶段 4：多 Agent 基础

- 实现 ProviderRegistry。
- 实现 OverallStatusReducer。
- 预留 ClaudeCodeProvider / CustomScriptProvider。
- UI 支持查看单个 Agent 状态。

### 阶段 5：体验增强

- 开机启动。
- 横版/竖版切换。
- 大小、透明度配置。
- 菜单栏入口。
- 状态调试面板。
- 打包 `.app`。

## 15. 测试策略

优先测试非 UI 逻辑：

- `OverallStatusReducer`
- `CodexClassifier`
- `CustomScriptProvider` JSON 解析
- 配置加载
- 位置保存

UI 主要靠手动验证：

- 悬浮窗是否置顶
- 透明背景是否正常
- 拖拽是否顺滑
- 位置是否能恢复
- 多屏幕下是否跑到屏幕外

## 16. 需要进一步调研的问题

在写真实代码前，需要确认：

```bash
ps aux | rg -i "codex|openai"
ls -la ~/.codex
find ~/.codex -maxdepth 3 -type f | head
```

目标：

- Codex CLI 真实进程名。
- Codex App 真实进程名。
- `~/.codex` 下是否有稳定 session / log 文件。
- 是否能识别“工作中”和“等待用户”的日志标志。
- Codex App 打开但空闲时应如何判断。

## 17. 第一版范围

第一版建议交付：

- 独立 Swift Package。
- 原生 macOS 悬浮三色灯。
- 可拖拽。
- 记住位置。
- 多 Agent 核心抽象。
- CodexProvider。
- ProcessProbe + 简单 LogProbe。
- 聚合状态显示。
- 右键退出、重置位置、刷新状态。

第一版暂不做：

- 完整设置页。
- 完整开机启动。
- 完整多 Agent UI。
- App Store 分发。
- 复杂日志解析。
- 对其他 Agent 的深度支持。

## 18. 命名约定

项目名：

```text
AgentTrafficLight
```

目录名：

```text
agent-traffic-light
```

模块命名：

- 通用核心使用 `Agent` 前缀。
- 具体实现使用 Provider 名称前缀，例如 `CodexProvider`。
- UI 不出现 `Codex` 这种具体 Agent 名称，除非是单个 Agent 列表项。

## 19. 风险与取舍

最大风险不是 UI，而是状态判断准确性。

进程存在不等于正在工作，App 打开也不等于正在工作。第一版可以接受“足够有用但不完美”的判断，后续通过日志、session、文件活动和用户反馈逐步提高准确性。

为了后续扩展，核心架构从第一天就按多 Agent 设计。但实现上不要过度工程化，第一版只落地 CodexProvider 和聚合灯。

## 20. 下一步

建议下一步先做两件事：

1. 调研本机 Codex 运行时状态：

```bash
ps aux | rg -i "codex|openai"
ls -la ~/.codex
find ~/.codex -maxdepth 3 -type f | head
```

2. 创建真实代码目录：

```text
/Users/doumengzhe/littleHLD/agent-traffic-light/
```

真实代码创建后，本文档继续作为方案基准。代码实现和文档变更分开提交，避免方案讨论污染可运行项目。
