# Claude GUI — 项目进度文档

## 项目概述

基于 SwiftUI + SwiftTerm 的 macOS 原生桌面应用，将 `claude` CLI 包装成图形界面，支持浏览器标签式多会话管理。

## 技术栈

- **UI**: SwiftUI (macOS 14.0+)
- **终端模拟**: [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) v1.13.0 (SPM 依赖)
- **进程管理**: SwiftTerm 内置 `LocalProcessTerminalView`（PTY forkpty 方式）

## 当前进度

**整体状态: 轮询修复完成 — 侧边栏自动刷新 agent 会话列表，标签栏同步显示**

### 已完成

| 文件 | 状态 | 说明 |
|------|------|------|
| `Package.swift` | done | SPM 配置，依赖 SwiftTerm |
| `ClaudeGUIApp.swift` | done | @main 入口，Cmd+T/W/1-9 快捷键 |
| `Models/Session.swift` | done | 会话数据模型 (Codable) |
| `Models/SessionManager.swift` | done | 会话管理 + UserDefaults 持久化 |
| `Services/TerminalService.swift` | done | 终端进程注册/终止 |
| `Views/TerminalView.swift` | done | SwiftTerm NSViewRepresentable 封装 |
| `Views/TabBarView.swift` | done | 浏览器式标签栏（主标签 + 子标签 + 新增按钮） |
| `Views/WelcomeView.swift` | done | 空状态欢迎页 + 快捷键提示 |
| `Views/ContentView.swift` | done | 根布局（标签栏 + 概览/终端/Welcome 切换） |

### 已修复（2026-05-23）

1. ✅ **编译验证** — `swift build` 编译通过，无错误无警告
2. ✅ **重复 Equatable extension** — 已删除 `ContentView.swift` 中的重复声明
3. ✅ **SwiftTerm API 签名** — `NativeColor` 不存在，改用 `SwiftTerm.Color(red:green:blue:)`（16-bit 值）
4. ✅ **Label 误用** — `Label(session.createdAt, style: .date)` 改为 `Text(session.createdAt, style: .date)`
5. ✅ **重复 terminateProcess** — TabBarView 中的冗余调用已移除
6. ✅ **应用启动验证** — `swift run ClaudeGUI` 成功启动，进程正常运行
7. ✅ **claude 命令路径** — 自动查找 nvm 安装的 claude 二进制，解决 GUI 应用 PATH 问题
8. ✅ **复制/粘贴** — 在 App 层面转发 Cmd+C/V/A 到活跃终端
9. ✅ **架构重构** — 从多标签改为侧边栏 + 单终端模式
10. ✅ **Xcode 项目创建** — 手动生成 `ClaudeGUI.xcodeproj`，含 SwiftTerm SPM 依赖
11. ✅ **App Sandbox 关闭** — entitlements 文件设置 `com.apple.security.app-sandbox = false`
12. ✅ **标签栏集成** — TabBarView 通过 NSHostingView 嵌入 MainWindowController
13. ✅ **主标签/子标签** — Overview 标签显示所有 agents 总览，子标签为各 agent 终端
14. ✅ **标签栏回调** — onSelect/onClose/onCreate/onOverview 回调连接终端管理
15. ✅ **轮询修复** — `claude agents --json` 子进程输出解析修复，交互式会话无 name/status 字段需 optional
16. ✅ **管道死锁修复** — readDataToEndOfFile 移到 waitUntilExit 之前避免管道缓冲区满导致死锁

## Xcode 打开方式

直接用 Xcode 打开 `ClaudeGUI/ClaudeGUI.xcodeproj`，Cmd+R 运行。

## 核心架构

```
ClaudeGUIApp (AppDelegate → MainWindowController)
  └── MainWindowController (NSWindowController)
        ├── NSSplitView (HSplitView)
        │     ├── 左: SidebarView (会话列表)
        │     │     ├── Header: "Sessions" + 新增按钮
        │     │     ├── SessionRow × N (每个会话一行)
        │     │     └── Footer: 会话计数
        │     └── 右: RightContainer
        │           ├── TabBarView (标签栏 — NSHostingView 嵌入 SwiftUI)
        │           │     ├── 主标签: "All Sessions" (Overview)
        │           │     ├── 子标签 × N (每个 claude agent)
        │           │     └── "+" 新增按钮
        │           └── TerminalContainer (终端区)
        │                 ├── OverviewView (主标签内容 — agents 总览)
        │                 └── LocalProcessTerminalView × N (各 agent 终端)
        └── 快捷键: Cmd+T/W/C/V/A, Cmd+1-9
```

## 数据流

```
点击侧边栏 "+"
  → SessionManager.createSession()
    → sessions.append(newSession), activeSessionId 更新
    → ContentView 渲染新 TerminalViewRepresentable (isActive=true)
      → 其他终端 isActive 变为 false → 隐藏
      → makeNSView 创建 LocalProcessTerminalView
        → tv.startProcess(shell, ["-c", "... && claude"])
        → PTY 通过 forkpty 创建，claude 在子进程中启动

点击侧边栏某个会话
  → SessionManager.switchToSession(id)
    → activeSessionId 更新
    → ContentView 更新 ForEach 中 isActive 绑定
      → 目标终端 opacity=1, 允许 hit testing
      → 其他终端 opacity=0, 禁止 hit testing

Cmd+C / Cmd+V
  → ClaudeGUIApp.commands 捕获
    → TerminalService.shared.getTerminalView(for: activeSessionId)
      → tv.copy(self) / tv.paste(self)

关闭会话
  → SessionManager.closeSession(id)
    → TerminalService.terminateProcess(id)
      → LocalProcessTerminalView.terminate()
    → sessions 列表移除
```

## 所有源文件完整内容

以上各文件均已创建在 `ClaudeGUI/Sources/ClaudeGUI/` 目录下，内容已通过 Read 工具确认。
