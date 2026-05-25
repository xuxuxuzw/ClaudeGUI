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
