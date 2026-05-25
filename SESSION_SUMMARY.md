# 会话总结 (2026-05-25)

## 原始问题
用户反馈 ClaudeGUI 应用中无法滚动终端内容、无法选中文字、终端样式异常、内容被左侧菜单遮挡。

## 根因分析

### 1. 终端无法滚动
`claude` CLI 运行时向终端发送备用屏幕缓冲区（alternate screen buffer）的转义序列（`\x1b[?47h`, `\x1b[?1047h`, `\x1b[?1049h`）。SwiftTerm 的备用缓冲区 `scrollback: nil`，导致 `yDisp` 始终为 0，`scrollUp`/`scrollDown` 实际上不执行任何操作。

### 2. 无法选中文字
`TerminalView.allowMouseReporting` 默认为 `true`，当 `claude` CLI 启用鼠标报告模式时，鼠标点击事件被转发给 PTY 进程而非用于文本选择。

### 3. 终端样式异常
`makeTerminal()` 中先调用 `configureNativeColors()` 设置系统默认文字/背景色，再直接设置 `terminal.backgroundColor/foregroundColor`（SwiftTerm Color 值），两者冲突。`mapColor()` 使用 `nativeForegroundColor/nativeBackgroundColor` 来渲染默认颜色，因此实际渲染的是系统默认颜色而非 AppTheme 颜色。

## 已修改的文件

### DragDropTerminalView.swift
- 新增 `escapeBuffer` 属性缓冲跨数据块的转义序列片段
- 新增 `dataReceived(slice:)` 覆盖方法，过滤 CSI ? 47/1047/1049 h/l 转义序列
- 新增 `allowMouseReporting = false` 使鼠标用于文本选择而非转发给 PTY

### Theme.swift
- 新增 `termBgNS` 和 `termFgNS` 计算属性，将 SwiftTerm Color 转为 NSColor

### MainWindowController.swift
- `makeTerminal()` 改用 `nativeBackgroundColor/nativeForegroundColor` 替代 `configureNativeColors()` + 直接属性设置
- `sidebarHostingView` 增加 `clipsToBounds = true`

## 当前状态

所有修改均编译通过，但用户反馈实际运行效果仍不理想：
- 终端样式仍然不对
- 内容仍感觉被左侧菜单遮挡
- 需要进一步调试

## 可能还需要排查的方向

1. **NSSplitView 布局时序问题**：`launchOverviewTerminal()` 在 `convenience init()` 中调用时，`terminalContainer.bounds` 可能还是 zero rect，导致终端初始大小错误
2. **终端字体大小/行列计算**：`setupOptions(width:height:)` 依赖 `frame.width/height` 计算 cols/rows，如果初始 frame 为零，终端尺寸可能不正确
3. **NSHostingView 背景**：macOS 上 NSHostingView 可能有不透明背景，需要显式设置或使用 `allowsHitTesting(false)` 避免拦截事件
4. **`claude` CLI 的输出格式**：可能发送了额外的控制序列影响终端渲染
5. **备用屏幕过滤器的边界情况**：分块数据的转义序列可能未完全过滤

## 相关工作

- SwiftTerm 源码位置：`ClaudeGUI/.build/checkouts/SwiftTerm/Sources/SwiftTerm/`
- 终端视图相关文件：`MacTerminalView.swift`（scrollWheel 处理）、`AppleTerminalView.swift`（渲染）、`MacLocalTerminalView.swift`（PTY 集成）
- `TerminalViewRepresentable.swift` 包含类似的颜色设置问题但当前未被使用（应用通过 `MainWindowController` 启动）

---

# 会话总结 (2026-05-27) — 滚动条和鼠标滚轮修复

## 问题 1：终端启动后无内容/无滚动条

### 根因
`MainWindowController.convenience init()` 调用链：
```
init() → setupUI() → launchOverviewTerminal() → makeTerminal()
```
此时 `terminalContainer` 刚被 `addSubview` 加入 `NSSplitView`，尚未布局，`terminalContainer.bounds` 为 `.zero`。

`DragDropTerminalView(frame: .zero)` 传给 SwiftTerm，内部 `setupOptions(width:height:)` 计算出 `cols=0, rows=0`，终端以零尺寸初始化。后续即使容器 resize 触发了 `setFrameSize` → `processSizeChange`，cell 尺寸在零帧初始化阶段已异常，终端始终无法正确渲染。

### 修复（MainWindowController.swift）
```swift
// makeTerminal() 中：
let frame = terminalContainer.bounds.isEmpty
    ? NSRect(x: 0, y: 0, width: 800, height: 600)
    : terminalContainer.bounds
let tv = DragDropTerminalView(frame: frame)
```
当 bounds 为空时使用 800×600 兜底帧，确保 SwiftTerm 正常初始化 cell 尺寸。

### 补充修复
```swift
terminalContainer.autoresizesSubviews = true
```
确保容器 resize 时子视图（终端）自动跟随。

---

## 问题 2：鼠标滚轮无法滚动对话内容

### 根因
claude CLI 使用**交替屏幕缓冲区**（alternate screen buffer）渲染 TUI。SwiftTerm 源码中：

```swift
// MacTerminalView.swift — scrollWheel()
public override func scrollWheel(with event: NSEvent) {
    if event.deltaY > 0 { scrollUp(lines: velocity) }
    else { scrollDown(lines: velocity) }
}

// AppleTerminalView.swift — canScroll
public var canScroll: Bool {
    return !terminal.isDisplayBufferAlternate && ...
}
```

交替缓冲区模式下 `canScroll = false`，`scrollUp/scrollDown` 操作 `yDisp` 偏移但交替缓冲区的 `scrollback = nil`，`yDisp` 始终为 0，滚轮事件变成空操作。

### 方案探索

**尝试 1（失败）：** 在 `DragDropTerminalView` 中 override `scrollWheel`，交替缓冲区时主动发送 VT 序列给 PTY。

失败原因：SwiftTerm 的 `scrollWheel` 是 `public` 非 `open`（Swift 中 `public override` 跨模块不允许），`isDisplayBufferAlternate` 是 `internal`（外部不可访问）。

**最终方案：** 在 `MainWindowController` 中通过 `NSEvent.addLocalMonitorForEvents(matching: .scrollWheel)` 全局拦截滚轮事件。

### 修复（MainWindowController.swift）

```swift
// setupUI() 中注册：
NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
    return self?.handleScrollWheel(event) ?? event
}
```

`handleScrollWheel()` 逻辑：
1. 检查窗口聚焦、活动终端可见
2. 检查 `term.canScroll == false`（交替缓冲区模式）— 如果为 true 则放行让 SwiftTerm 自己处理
3. 检查鼠标在终端区域内
4. 累加 `deltaY` 到 `scrollAccumulator`（支持触控板平滑滚动，每次事件 `deltaY` 可能 <1，直接 `Int()` 截断为 0）
5. 达到阈值 1.0 后，发送 **Page Up** (`ESC [ 5 ~`) / **Page Down** (`ESC [ 6 ~`) 序列

> **注意：** 最初使用光标上/下序列 (`ESC [ A` / `ESC [ B`)，但这会导航 claude 的输入历史而非滚动对话内容。Page Up/Down 才是正确的对话滚动方式。

### 涉及文件

| 文件 | 修改内容 |
|------|---------|
| `MainWindowController.swift` | `makeTerminal()` 零帧兜底、`autoresizesSubviews`、`scrollWheel` 事件拦截 + `handleScrollWheel()` |
| `DragDropTerminalView.swift` | 无修改（尝试了 override 但最终回退） |
| `TerminalView.swift` | 添加了 `TerminalHostingView` 包装器（未被运行时使用，但保留以备后续 SwiftUI 路径） |
| `ContentView.swift` | 添加了 `GeometryReader` 确保帧传递（同上前未被使用） |

---

# 会话总结 (2026-05-25) — 权限模式切换功能

## 需求背景

用户阅读了 [Claude Code 权限模式文章](https://oscar.blog.csdn.net/article/details/159617638)，希望在 ClaudeGUI 中加入权限模式切换功能。Claude Code CLI 支持 6 种权限模式（`default`、`acceptEdits`、`plan`、`auto`、`dontAsk`、`bypassPermissions`），在终端中通过 `Shift+Tab` 循环切换。

## 最终方案

**侧边栏点击按钮 + 快捷键 `Cmd+Shift+T`，每次发送一次 `\x1b[Z`（Shift+Tab 终端转义序列）到终端，让 Claude CLI 自己循环权限模式。**

不做计算、不追踪状态、不假装知道当前模式。

## 方案演变过程

### 第一阶段：新建会话时指定模式

最初方案是在新建会话对话框中添加权限模式 Picker，创建会话时传入 `--permission-mode` 参数。这只能设置初始模式，用户反馈希望运行时也能切换。

### 第二阶段：运行时下拉选择 + 计算 Shift+Tab 次数

在侧边栏底部添加 Picker，选择目标模式后计算从当前模式到目标模式需要几次 `Shift+Tab`，发送对应次数。

**问题**：`@Published var currentPermissionMode` 假装知道 Claude CLI 的当前模式，但实际上：
- 用户可能在终端里直接按了 `Shift+Tab`（绕过选择器）
- 会话重启后模式重置
- 状态栏文字可能不显示

状态不同步导致发送的 Shift+Tab 次数错误。

### 第三阶段（最终）：纯动作式，每次发一次 Shift+Tab

- 移除 `currentPermissionMode` 状态追踪
- Picker → Menu → 简单 Button（点击整行触发）
- `setPermissionMode(target:)` → `cyclePermissionMode()`（无参数，固定发 1 次）
- `shiftTabCount` 等所有计算逻辑全部删除
- 新增 `Cmd+Shift+T` 全局快捷键

## 架构分析：为什么不能用 MCP 通信

用户提出用 MCP（Model Context Protocol）来切换权限。

**结论**：不可行，MCP 的方向是反的。

| | MCP 设计方向 | 我们需要的方向 |
|---|---|---|
| 通信模式 | Claude → 外部工具 | 外部 UI → Claude |
| 协议用途 | Claude 调用文件系统/Git/浏览器等 | 外部控制 Claude 的权限模式 |

VS Code 插件能做到是因为它**不是在终端里跑 Claude**，而是通过自己的 MCP server (`ide`) 与 headless Claude 子进程通信，权限模式通过扩展设置直接控制。ClaudeGUI 运行的是原始终端会话（SwiftTerm PTY），唯一的输入通道就是终端 stdin。

## 涉及文件

| 文件 | 新增/修改 | 内容 |
|------|----------|------|
| `Models/PermissionMode.swift` | **新增** | 权限模式枚举，6 种模式 + `cliFlag`、`displayName`、`description`、持久化默认模式 |
| `Localization.swift` | 修改 | 新增 `permissionMode`（切换权限模式 / Cycle Permission Mode）、`permissionModeDesc` |
| `MainWindowController.swift` | 修改 | `SidebarCallback` 新增 `onCyclePermissionMode`；`cyclePermissionMode()` 方法发送 `\x1b[Z`；`handleKeyDown` 新增 `Cmd+Shift+T`；新建会话支持 `--permission-mode` 参数 |
| `Views/TabBarView.swift` | 修改 | 侧边栏底部新增 "切换权限模式" 按钮（整行可点击） |
| `project.pbxproj` | 修改 | 注册 PermissionMode.swift 到 Xcode 项目 |

## 构建与部署经验

### 问题：命令行编译的 app 和 Xcode 编译的行为不一致

用户反馈 `xcodebuild` 编译出来的 app 没有切换权限模式功能，但 Xcode GUI 编译的有。

### 排查

1. `strings | grep "切换权限模式"` — 二进制中无此字符串（false negative，Swift 字符串可能不以 ASCII 存储）
2. `strings | grep "cyclePermission"` — 有结果，代码确实在
3. `nm | grep "cyclePermission"` — 符号表中有 `cyclePermissionMode`，确认代码编译进了

### 根因：`cp -R` 没有正确覆盖旧 app bundle

macOS 的 app bundle 是目录结构，`cp -R` 对已存在的 bundle 行为不可靠，可能只替换了部分文件而未完整覆盖。

### 修复

```bash
# 正确方式：先删除再复制，使用 ditto（macOS 推荐）
rm -rf /path/to/ClaudeGUI.app
ditto /DerivedData/.../Release/ClaudeGUI.app /path/to/ClaudeGUI.app
```

`ditto` 是 macOS 专门处理 bundle 复制的工具，能正确处理签名、扩展属性、符号链接。

### 教训

| 场景 | 错误做法 | 正确做法 |
|------|---------|---------|
| 覆盖 app bundle | `cp -R src.app dst.app` | `rm -rf dst.app && ditto src.app dst.app` |
| 验证功能是否编译进 | `strings \| grep`（对 Swift 字符串不可靠） | `nm \| grep` 查符号表 |
| 清缓存重编译 | 直接 rebuild | `rm -rf DerivedData` → rebuild |
