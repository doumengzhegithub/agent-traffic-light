# Agent Traffic Light 代码架构设计

> 本文档用于指导真实 Swift 项目落地。方案背景见 `docs/agent-traffic-light-design.md`。

## 1. 架构目标

第一版要做一个可运行、可扩展、可测试的 macOS 悬浮红绿灯应用。

核心目标：

- UI 只展示状态，不直接读取进程、日志或文件。
- Agent 状态探测通过 Provider 插件化接入。
- Codex 是第一版 Provider，但核心模型不能绑定 Codex。
- 系统调用集中封装，方便替换、测试和处理权限问题。
- 第一版先做小闭环，后续再扩展设置页、多 Agent 列表、打包和开机启动。

## 2. 顶层模块

真实代码目录：

```text
agent-traffic-light/
├── Package.swift
├── README.md
├── Makefile
├── Sources/
│   └── AgentTrafficLight/
│       ├── App/
│       ├── UI/
│       ├── ViewModels/
│       ├── Core/
│       ├── Providers/
│       ├── Config/
│       └── System/
└── Tests/
    └── AgentTrafficLightTests/
```

模块职责：

| 模块 | 职责 | 允许依赖 |
| --- | --- | --- |
| `App` | 应用启动、生命周期、窗口装配、菜单动作路由 | `UI`, `ViewModels`, `Core`, `Providers`, `Config`, `System` |
| `UI` | SwiftUI 视图和 AppKit 窗口外壳 | `ViewModels`, `Core` |
| `ViewModels` | UI 状态适配、用户动作处理、主线程状态发布 | `Core`, `Config` |
| `Core` | Agent 领域模型、Provider 协议、状态监控、聚合规则 | 无下层业务依赖 |
| `Providers` | 具体 Agent 状态探测实现，例如 Codex | `Core`, `System` |
| `Config` | 偏好设置、窗口位置、Provider 配置 | `Core` |
| `System` | 进程扫描、文件活动扫描、Shell 执行、时间源 | 无业务依赖 |

依赖方向必须保持单向：

```text
App -> UI -> ViewModels -> Core
App -> Providers -> Core
Providers -> System
ViewModels -> Config
Config -> Core
```

禁止反向依赖：

- `Core` 不依赖 `UI`、`Providers`、`System`。
- `UI` 不依赖 `Providers` 或 `System`。
- `System` 不知道 Codex、Agent、红绿灯这些业务概念。

## 3. App 模块

建议文件：

```text
Sources/AgentTrafficLight/App/
├── AgentTrafficLightApp.swift
├── AppDelegate.swift
├── AppCompositionRoot.swift
└── MenuController.swift
```

职责划分：

- `AgentTrafficLightApp.swift`
  - SwiftUI `@main` 入口。
  - 接入 `NSApplicationDelegateAdaptor`。

- `AppDelegate.swift`
  - 创建悬浮窗口。
  - 管理应用生命周期。
  - 应用退出、激活、窗口恢复。

- `AppCompositionRoot.swift`
  - 组装依赖。
  - 创建 `ProcessScanner`、`FileActivityScanner`、`CodexProvider`、`AgentStatusMonitor`、`TrafficLightViewModel`。
  - 第一版可以硬编码启用 CodexProvider。

- `MenuController.swift`
  - 构建右键菜单。
  - 菜单项包括刷新状态、重置位置、退出。
  - 菜单动作转发给 ViewModel 或 AppDelegate，不直接操作业务状态。

## 4. UI 模块

建议文件：

```text
Sources/AgentTrafficLight/UI/
├── FloatingPanel.swift
├── TrafficLightView.swift
├── TrafficLightDot.swift
├── AgentListView.swift
├── AgentRowView.swift
└── StatusPopoverView.swift
```

职责划分：

- `FloatingPanel.swift`
  - `NSPanel` 或 `NSWindow` 子类/包装。
  - 负责透明背景、置顶层级、无标题栏、拖拽、右键菜单挂载。
  - 只处理窗口行为，不判断 Agent 状态。

- `TrafficLightView.swift`
  - 竖版三灯主视图。
  - 根据 `overallState` 决定高亮哪盏灯。
  - 支持紧凑尺寸，不包含状态探测逻辑。

- `TrafficLightDot.swift`
  - 单个灯的绘制。
  - 输入颜色、是否激活、是否错误态。

- `AgentListView.swift`
  - 后续展开面板使用。
  - 第一版可以先保留简单实现或暂不接入。

- `AgentRowView.swift`
  - 单个 Agent 行展示。
  - 展示名称、状态、详情。

- `StatusPopoverView.swift`
  - 后续点击悬浮灯时展示状态列表。
  - 第一版可作为预留模块。

UI 输入应该来自 ViewModel 的只读状态，例如：

```swift
struct TrafficLightDisplayState {
    let overallState: AgentState
    let agents: [AgentSnapshot]
    let lastUpdatedAt: Date?
}
```

## 5. ViewModels 模块

建议文件：

```text
Sources/AgentTrafficLight/ViewModels/
├── TrafficLightViewModel.swift
└── AgentDisplayMapper.swift
```

职责划分：

- `TrafficLightViewModel.swift`
  - `@MainActor ObservableObject`。
  - 持有 `AgentStatusMonitor`。
  - 发布 `TrafficLightDisplayState`。
  - 处理用户动作：手动刷新、暂停/恢复轮询、重置位置。

- `AgentDisplayMapper.swift`
  - 将 `AgentSnapshot` 映射为 UI 友好的标题、颜色、短描述。
  - 让 SwiftUI View 保持轻量。

ViewModel 不应该直接执行 `ps`、读取文件或解析日志。

## 6. Core 模块

建议文件：

```text
Sources/AgentTrafficLight/Core/
├── AgentState.swift
├── AgentSnapshot.swift
├── AgentStatusProvider.swift
├── AgentStatusMonitor.swift
├── OverallStatusReducer.swift
├── ProviderRegistry.swift
└── Clock.swift
```

核心类型：

```swift
enum AgentState: Equatable {
    case idle
    case working
    case waitingForUser
    case error
    case unknown
}
```

```swift
struct AgentSnapshot: Equatable {
    let agentID: String
    let displayName: String
    let state: AgentState
    let confidence: Double
    let source: String
    let lastActivityAt: Date?
    let detail: String?
}
```

```swift
protocol AgentStatusProvider {
    var id: String { get }
    var displayName: String { get }
    func snapshot() async -> AgentSnapshot
}
```

`AgentStatusMonitor` 职责：

- 持有多个 `AgentStatusProvider`。
- 定时并发收集快照。
- 调用 `OverallStatusReducer` 得到总体状态。
- 向 ViewModel 输出状态流。

建议输出模型：

```swift
struct AgentStatusReport: Equatable {
    let overallState: AgentState
    let snapshots: [AgentSnapshot]
    let collectedAt: Date
}
```

`OverallStatusReducer` 职责：

- 纯函数，无副作用。
- 根据快照列表聚合总状态。
- 第一版优先级：

```text
waitingForUser > working > error > unknown > idle
```

注意：如果没有任何 Provider，建议返回 `unknown`，避免把配置错误伪装成空闲。

## 7. Providers 模块

建议目录：

```text
Sources/AgentTrafficLight/Providers/
├── Codex/
│   ├── CodexProvider.swift
│   ├── CodexProcessProbe.swift
│   ├── CodexLogProbe.swift
│   ├── CodexClassifier.swift
│   └── CodexRuntimeSignal.swift
├── ClaudeCode/
│   └── ClaudeCodeProvider.swift
└── Custom/
    └── CustomScriptProvider.swift
```

第一版只实现 `Codex`，其他 Provider 保留目录或后续再建。

### 7.1 CodexProvider

职责：

- 调用 `CodexProcessProbe` 获取进程信号。
- 调用 `CodexLogProbe` 获取日志/文件活动信号。
- 调用 `CodexClassifier` 进行状态分类。
- 输出通用 `AgentSnapshot`。

数据流：

```text
ProcessScanner -> CodexProcessProbe -> CodexRuntimeSignal
FileActivityScanner -> CodexLogProbe -> CodexRuntimeSignal
CodexRuntimeSignal -> CodexClassifier -> AgentState
CodexProvider -> AgentSnapshot
```

### 7.2 CodexProcessProbe

职责：

- 从 `ProcessScanner` 获取进程列表。
- 识别 Codex CLI / Codex App。
- 不直接决定 working/idle，只输出进程存在性和进程类型。

当前本机可观察到的进程特征：

```text
node /usr/local/bin/codex
.../@openai/codex-darwin-x64/.../bin/codex
/Applications/Codex.app/Contents/Resources/node_repl
/Applications/Codex.app/Contents/Resources/codex app-server --listen stdio://
```

### 7.3 CodexLogProbe

职责：

- 检查 `~/.codex` 下稳定文件的最近活动。
- 第一版优先观察：

```text
~/.codex/logs_2.sqlite
~/.codex/logs_2.sqlite-wal
~/.codex/state_5.sqlite
~/.codex/state_5.sqlite-wal
~/.codex/history.jsonl
~/.codex/session_index.jsonl
```

- 不在第一版直接读取大 SQLite 内容。
- 先用文件修改时间判断近期活动。
- 后续再增加 SQLite/JSONL 解析。

### 7.4 CodexClassifier

职责：

- 把进程信号、文件活动信号、关键词信号合并为 `AgentState`。
- 保持纯逻辑，方便单测。

第一版分类规则：

```text
有等待用户关键词 => waitingForUser
否则近期文件持续活动 => working
否则存在 Codex 进程 => idle
否则无进程且无近期活动 => idle
否则 => unknown
```

保守策略：

- 不因为 Codex App 打开就判定 working。
- 没有把握时降低置信度。
- 等待用户状态优先级高于工作中。

## 8. Config 模块

建议文件：

```text
Sources/AgentTrafficLight/Config/
├── AgentConfig.swift
├── AppPreferences.swift
├── PositionStore.swift
└── UserDefaultsStore.swift
```

职责划分：

- `AgentConfig.swift`
  - 描述 Provider 配置。
  - 第一版可以有模型但不读取外部配置文件。

- `AppPreferences.swift`
  - 轮询间隔、窗口尺寸、显示方向等偏好。
  - 第一版只需要轮询间隔和默认窗口设置。

- `PositionStore.swift`
  - 保存和恢复悬浮窗位置。
  - 负责屏幕边界校正，避免恢复到不可见位置。

- `UserDefaultsStore.swift`
  - 对 `UserDefaults` 做薄封装。
  - 便于测试时替换。

## 9. System 模块

建议文件：

```text
Sources/AgentTrafficLight/System/
├── ShellCommand.swift
├── ProcessScanner.swift
├── FileActivityScanner.swift
└── SystemClock.swift
```

职责划分：

- `ShellCommand.swift`
  - 统一执行命令。
  - 返回 exit code、stdout、stderr。
  - 设置超时，避免轮询卡死。

- `ProcessScanner.swift`
  - 调用 `/bin/ps` 或 Foundation `Process`。
  - 输出结构化进程列表：

```swift
struct RunningProcess: Equatable {
    let pid: Int32
    let command: String
}
```

- `FileActivityScanner.swift`
  - 给定路径列表，返回存在性和最近修改时间。
  - 不解析业务含义。

- `SystemClock.swift`
  - 提供当前时间。
  - 测试中可替换为固定时间。

## 10. 轮询与状态流

第一版建议使用 Swift Concurrency，不引入 Combine 复杂管线。

流程：

```text
AppCompositionRoot
  -> AgentStatusMonitor.start()
  -> Task loop every pollInterval
  -> providers.map { await snapshot() }
  -> OverallStatusReducer.reduce()
  -> ViewModel publishes display state on MainActor
  -> TrafficLightView redraws
```

轮询要求：

- 默认间隔 `1s`。
- 每次采集设置超时，避免卡住下一轮。
- 手动刷新复用同一条采集路径。
- App 退出时取消轮询 Task。

## 11. 错误处理

错误原则：

- Provider 内部错误不应该让整个应用崩溃。
- 单个 Provider 探测失败时返回 `unknown` 或 `error` 快照。
- 系统命令失败时带上 detail，便于调试。
- UI 第一版只显示灰灯/错误态，不弹频繁警告。

建议：

- `ProcessScanner` 失败：CodexProvider 返回 `unknown`，`source = "process-scan-failed"`。
- 文件不可访问：降低 confidence，不直接判定 error。
- 分类器输入为空：返回 `idle` 或 `unknown` 取决于是否存在 Provider。

## 12. 测试设计

第一版优先测试纯逻辑和系统边界封装。

测试目录：

```text
Tests/AgentTrafficLightTests/
├── OverallStatusReducerTests.swift
├── CodexClassifierTests.swift
├── CodexProcessProbeTests.swift
├── CodexLogProbeTests.swift
├── PositionStoreTests.swift
└── AgentStatusMonitorTests.swift
```

测试重点：

- Reducer 状态优先级。
- 空 Provider 时返回 `unknown`。
- Codex 进程特征匹配。
- 文件近期活动窗口判断。
- 等待用户关键词优先于 working。
- 窗口位置恢复时不会跑出屏幕。

UI 第一版主要手动验证：

- 悬浮窗置顶。
- 透明背景。
- 拖拽保存位置。
- 右键菜单可用。
- 三灯状态切换正常。

## 13. 第一版实施顺序

建议按以下顺序编码：

1. 创建 Swift Package、Makefile、README。
2. 实现 `Core`：`AgentState`、`AgentSnapshot`、`AgentStatusProvider`、`OverallStatusReducer`。
3. 实现 `System`：`ShellCommand`、`ProcessScanner`、`FileActivityScanner`。
4. 实现 `Providers/Codex`：进程探测、文件活动探测、分类器、Provider。
5. 实现 `AgentStatusMonitor` 和 `TrafficLightViewModel`。
6. 实现 `FloatingPanel`、`TrafficLightView`、右键菜单。
7. 实现 `PositionStore`。
8. 补齐核心单测。
9. 本机运行验证。

这样可以先把状态数据链路跑通，再接 UI，降低调试成本。

## 14. 架构审核

### 14.1 通过项

- 模块边界清楚：UI、领域模型、Provider、系统调用分离。
- 支持多 Agent：`AgentStatusProvider` 和 `AgentStatusMonitor` 从第一版就是多 Provider 结构。
- 可测试性足够：Reducer、Classifier、Probe 都可以脱离 UI 单测。
- macOS 能力集中：透明窗口、置顶、拖拽集中在 `UI/FloatingPanel`，不会污染 Core。
- Codex 探测可迭代：第一版先用进程和文件活动，后续可替换为更准的 SQLite/日志解析。

### 14.2 风险项

- `ps` 在沙箱或权限限制下可能失败，需要 `ProcessScanner` 明确错误输出。
- 用文件修改时间判断 working 会有误报，例如后台同步或非当前任务写入。
- Codex App 打开但空闲时容易被误判，需要分类器明确“进程存在只是 idle 信号”。
- 读取 `~/.codex` 的文件结构不是稳定公开接口，后续 Codex 更新可能改变路径。
- Swift Package 做 macOS App 可以启动 MVP，但后续打包 `.app` 可能需要 Xcode 工程或额外打包脚本。

### 14.3 修改建议

- 第一版不要直接解析 `logs_2.sqlite`，先把文件活动和进程识别做稳。
- `CodexClassifier` 必须有 confidence 字段输出，避免 UI 把低置信度判断展示得过于确定。
- `System` 层命令执行必须设置短超时。
- `PositionStore` 第一版就做屏幕边界校正，否则悬浮窗容易恢复到不可见位置。
- `AgentListView` 和 `StatusPopoverView` 可以先建文件但不接主流程，避免拖慢 MVP。

### 14.4 审核结论

该架构适合第一版落地。

主要原因是它把不稳定的 Codex 探测隔离在 Provider，把可稳定测试的状态聚合放在 Core，把 macOS 窗口细节限制在 UI/App 层。第一版实现时应控制范围，只交付 CodexProvider、聚合状态和悬浮灯主流程，不提前实现完整配置页和复杂多 Agent UI。
