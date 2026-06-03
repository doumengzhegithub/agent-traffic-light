# Agent Traffic Light 进度记录

更新时间：2026-06-03

## 当前状态

项目已经从方案阶段进入真实代码阶段。

仓库：

```text
https://github.com/doumengzhegithub/agent-traffic-light
```

本地目录：

```text
/Users/doumengzhe/littleHLD
```

Swift 子项目目录：

```text
/Users/doumengzhe/littleHLD/agent-traffic-light
```

## 已完成

- GitHub 远程已打通。
- 本地 `main` 已跟踪 `origin/main`。
- 已创建 Swift Package：`AgentTrafficLight`。
- 已落地第一批 Core 模块：
  - `AgentState`
  - `AgentSnapshot`
  - `AgentStatusProvider`
  - `AgentStatusReport`
  - `OverallStatusReducer`
  - `AgentStatusMonitor`
  - `ClockProvider`
- 已落地第一批 System 模块：
  - `ShellCommand`
  - `ShellCommandResult`
  - `ProcessScanner`
  - `RunningProcess`
  - `FileActivityScanner`
  - `FileActivity`
- 已落地第一批 Codex Provider：
  - `CodexProcessProbe`
  - `CodexLogProbe`
  - `CodexClassifier`
  - `CodexProvider`
- 已落地第一版 macOS 悬浮红绿灯原型：
  - AppKit `NSPanel` 透明置顶窗口
  - SwiftUI 三灯视图
  - 每秒轮询状态
  - 右键菜单：刷新、复制状态、重置位置、退出
- 已改为跟随 Codex CLI 终端窗口：
  - 仅当前台应用是 Terminal/iTerm2/Ghostty/Warp 且存在 Codex CLI 进程时显示
  - 自动定位到前台终端窗口左上角
  - 切到其他应用时自动隐藏
- 已增加 `make run-tty`，通过 `script(1)` 给原型启动进程提供 TTY 会话。
- 已增加第一版黄灯识别：
  - 最近有 Codex 运行日志事件时显示红灯
  - Codex CLI 仍在但没有近期运行事件时显示黄灯，表示等待用户输入
  - 当前台终端窗口标题包含 `[!]`、`Action Required`、`approval`、`confirm` 或 `permission` 时强制显示黄灯
  - 读取 `~/.codex/logs_2.sqlite` 中的真实 `ToolCall` 事件；当 `require_escalated` 请求晚于最近一次审批 decision 时显示黄灯
  - 如果 `ps` 或终端标题读取受限，但前台是终端且没有近期运行事件，则回退到黄灯，避免确认/授权场景误显示绿灯
  - Codex App 常驻但无 CLI 工作时保持绿灯
- 已增加右键 `Copy Status`，可把当前 provider 状态、source、confidence、last activity 和 detail 复制到剪贴板，方便排查误判。
- 已修复右键菜单触发路径，改为 AppKit hosting view 直接处理 `rightMouseDown`。
- 已改为支持后台运行：
  - `make start` 通过用户级 `launchctl` 服务后台启动，label 为 `com.littlehld.agent-traffic-light`
  - 生成 plist 到 `/tmp/agent-traffic-light.plist`
  - 可用时写入当前 PID 到 `/tmp/agent-traffic-light.pid`
  - 日志写入 `/tmp/agent-traffic-light.log`
  - `make stop` 停止后台进程
  - `make status` 查看运行状态
  - `make logs` 跟随日志
- 已增加子项目 `Makefile` 和 `README.md`。
- 已将测试从 `XCTest` 迁移到 Swift Testing。
- 已设置 Swift Package macOS target 为 macOS 14。
- `swift build` 已通过。
- `swift test` 已通过，当前 31 个测试全部通过。

## 环境状态

Command Line Tools 已整理并重新安装。

当前状态：

```text
xcode-select: /Library/Developer/CommandLineTools
Swift: Apple Swift version 6.1.2
CLT: Command Line Tools for Xcode 16.4
```

之前的问题：

- 旧 CLT 残留文件导致 `SwiftBridging` 重复定义。
- CLT 清理重装后解决。
- 当前 CLT 不提供完整 `XCTest.framework`/`xctest`，所以测试使用 Swift Testing。

## 最近提交

```text
465ea04 Record traffic light project progress
c13d176 Fix Swift package test environment
b09d8d1 Add Swift package core skeleton
```

## 下次继续点

下一步建议打磨第一版原型的可用性：

```text
提升 Codex 状态判定准确度：
- 等待用户状态识别
- 更稳定的日志/SQLite 活动判断
- App bundle 打包
- UI 手动验证和截图记录
```

建议顺序：

1. 从 `.codex` 近期日志或状态文件中提取等待用户关键词。
2. 区分 Codex App 后台常驻写入和真实任务工作中的写入。
3. 增加状态 popover，显示 provider 明细和最近更新时间。
4. 做 `.app` 打包脚本，降低启动门槛。
5. 手动验证悬浮窗置顶、拖拽、右键菜单和位置恢复。

恢复工作时先运行：

```bash
cd /Users/doumengzhe/littleHLD/agent-traffic-light
swift test
```
