# ClaudeGUI - 跨平台实现参考

## 1. 架构概览

```
+---------------------------+
|        主窗口              |
|  +--------+  +----------+ |
|  | 侧边栏  |  | 终端区域  | |
|  | (列表)  |  | (PTY)    | |
|  +--------+  +----------+ |
+---------------------------+
```

- **左侧栏**：会话列表，按状态分组，支持展开/收起
- **右侧终端**：多个终端实例，同一时刻只显示一个
- **轮询机制**：后台定时执行 `claude agents --json` 同步会话状态

## 2. CLI 命令参考

### 2.1 查询会话列表（JSON 格式）

```bash
claude agents --json
```

输出示例：
```json
[
  {
    "pid": 12345,
    "cwd": "/Users/dev/project-a",
    "kind": "background",
    "startedAt": 1748000000000,
    "sessionId": "ed586587-9a18-4467-9142-701e4574a21f",
    "name": "修复登录bug",
    "status": "working"
  }
]
```

字段说明：
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| pid | int | 是 | 进程 PID |
| cwd | string | 是 | 工作目录 |
| kind | string | 是 | 类型，`"background"` 或 `"interactive"` |
| startedAt | int64 | 是 | 启动时间戳（毫秒） |
| sessionId | string | 是 | 完整 UUID |
| name | string | 否 | 会话名称，interactive 会话可能为 null |
| status | string | 否 | 状态，可能为 null |

### 2.2 进入会话

```bash
# 注意：用 shortId（UUID 第一段，即第一个 "-" 之前的部分）
claude attach ed586587
```

- 不能用完整 UUID，否则报错 "No job matching"
- `--resume` 不适用于后台 agent，会报错 "Session is currently running as a background agent"

### 2.3 停止会话

```bash
claude stop ed586587
```

### 2.4 删除会话

```bash
claude rm ed586587
```

### 2.5 创建后台会话

```bash
claude --bg "修复 auth 模块里所有失败的单元测试，直到全部通过"
```

### 2.6 其他命令

```bash
claude agents          # TUI 界面查看所有会话
claude logs ed586587   # 打印指定会话的最近输出
claude respawn ed586587    # 重启已停止的会话，保留对话历史
claude respawn --all       # 重启所有已停止的会话
```

## 3. 核心数据结构

### 3.1 AgentSession（从 JSON 解析）

```swift
// 对应 claude agents --json 的每一条记录
struct AgentSession {
    let pid: Int
    let cwd: String          // 工作目录
    let kind: String         // "background" | "interactive"
    let startedAt: Int64     // 毫秒时间戳
    let sessionId: String    // 完整 UUID，如 "ed586587-9a18-4467-9142-701e4574a21f"
    let name: String?        // 可能为 null
    let status: String?      // 可能为 null
}
```

### 3.2 Session（UI 展示用）

```swift
struct Session {
    let id: UUID             // 从 sessionId 转换
    var name: String         // name ?? shortId
    var shortId: String      // sessionId 第一段，如 "ed586587"
    let createdAt: Date      // 从 startedAt 转换
    var workingDirectory: String
    var status: String       // "waiting" | "working" | "completed" | "idle"
}
```

### 3.3 shortId 提取逻辑

```python
# sessionId = "ed586587-9a18-4467-9142-701e4574a21f"
short_id = session_id.split("-")[0]  # => "ed586587"
```

### 3.4 状态映射

`claude agents --json` 返回的 `status` 字段值：
- `"waiting"` → 等待输入（绿色）
- `"working"` → 工作中（橙色）
- `"completed"` → 已完成（蓝色）
- `null` 或其他 → 空闲（灰色）

仅显示 `kind == "background"` 的会话，过滤掉 interactive。

## 4. 终端管理

### 4.1 终端实例模型

```
overviewTerminal   →  始终存在，运行 `claude agents`
sessionTerminals   →  Map<sessionId, Terminal>，按需创建
activeTerminal     →  当前显示的终端引用
```

### 4.2 创建终端

每个终端是一个伪终端（PTY）实例，运行 `/bin/zsh -l -c "命令"`。

### 4.3 切换终端

- 新终端：创建 PTY，加入容器，设为 active
- 已有终端：隐藏当前，显示目标，设为 active
- 同一终端：不操作

### 4.4 关闭/停止会话

- 关闭终端只是从 UI 移除，不 kill 进程（daemon 会自动 respawn）
- 停止会话通过 `claude stop <shortId>` CLI 命令
- 删除会话通过 `claude rm <shortId>` CLI 命令

### 4.5 拖拽文件

拖拽文件到终端时，将文件路径格式化为 `@/path/to/file` 写入 PTY。
多个文件用空格连接：`@/path1 @/path2`。

## 5. 轮询同步机制

### 5.1 流程

```
启动 → 立即执行一次 pollAgentSessions()
     → 每 5 秒定时执行
     → 解析 JSON → 更新 sessionManager.sessions
     → UI 自动刷新
```

### 5.2 注意事项

- CLI 命令在主线程同步执行（阻塞短暂），UI 更新回主线程
- 读取 stdout 和 stderr 时注意管道死锁风险
- sessionId 比较时统一转小写（UUID 大小写敏感）

## 6. Claude 路径查找

搜索顺序：
1. `~/.nvm/versions/node/<最新版本>/bin/claude`
2. 如果找不到，回退到 `claude`（依赖 PATH）

## 7. 侧边栏 UI 结构

```
[主题按钮] [语言按钮]
─────────────────────
[所有会话]           ← 回到概览终端
[新建会话]           ← 弹窗输入任务 + 选目录
─────────────────────
▼ 等待输入 (3)       ← 可折叠分组，整行可点击
    ed586587 修复登录bug
    3a2f1b00 优化首页
    ...
▼ 工作中 (1)
    ...
▼ 已完成 (0)
    暂无会话
▼ 空闲 (2)
    ...
─────────────────────
3 个代理
```

### 7.1 分组规则

| 分组 | 颜色 | 过滤条件 |
|------|------|----------|
| 等待输入 | 绿色 | status == "waiting" |
| 工作中 | 橙色 | status == "working" |
| 已完成 | 蓝色 | status == "completed" |
| 空闲 | 灰色 | 不属于以上三种 |

### 7.2 会话行显示

格式：`[状态圆点] [shortId] [会话名]`

- shortId 等宽字体显示
- 活跃会话右侧有蓝色竖条指示
- 整行可点击切换
- 右键弹出菜单：停止会话 / 删除会话

## 8. 新建会话弹窗

```
+----------------------------------+
| 新建会话                         |
+----------------------------------+
| 请输入任务描述：                  |
| [输入框 placeholder: 例如：...]  |
| /Users/dev                       |  ← NSPathControl，点击可选目录
+----------------------------------+
|        [OK]    [Cancel]          |
+----------------------------------+
```

确认后执行：`claude --bg "任务描述"`，工作目录为所选目录。

## 9. 快捷键

| 快捷键 | 功能 |
|--------|------|
| Cmd+R | 手动刷新会话列表 |
| Cmd+1~9 | 快速切换到第 N 个会话 |

## 10. 本地化

支持中文（默认）和英文，所有 UI 文本通过 L10n 枚举管理，切换语言即时刷新。

## 11. 主题系统

### 11.1 架构

```
ColorScheme 枚举 (.basic / .clearDark / .clearLight)
        ↓
ThemeManager 单例 (@Published var current)
        ↓
AppTheme 静态计算属性 (bgDeep, bgBase, textPrimary, ...)
        ↓
SwiftUI 视图自动刷新
```

- `ThemeManager.shared` 管理当前配色方案，通过 `@Published var current` 驱动 SwiftUI 刷新
- `AppTheme` 的所有颜色属性是计算属性，读取 `ThemeManager.shared.current` 返回对应值
- 主题选择通过 UserDefaults（key: `"claudeGUI_colorScheme"`）持久化

### 11.2 三种配色方案

| 方案 | 按钮文字 | 背景风格 | 终端 |
|------|---------|---------|------|
| Basic | 基础/Basic | 纯深灰不透明 | 深色 #19191E |
| Clear Dark | 暗色/Dark | 蓝灰半透明 | 蓝紫深色 #141420 |
| Clear Light | 亮色/Light | 纯白 | 白底 #ffffff |

Clear Dark 和 Clear Light 的配色取自 macOS Terminal.app 的同名方案。

### 11.3 终端颜色同步

终端颜色通过 `AppTheme.termBg` / `AppTheme.termFg` / `AppTheme.termContainerBg` 统一管理，在 `makeTerminal()` 和 `TerminalViewRepresentable` 中使用，替代了之前的硬编码值。

### 11.4 新增主题步骤

1. 在 `ColorScheme` 枚举中添加新 case
2. 在 `AppTheme` 每个计算属性的 switch 中添加对应色值
3. 在 `themeName()` 函数中添加中英文名称
4. 更新 DESIGN.md 中的色值表
