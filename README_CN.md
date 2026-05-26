# ClaudeGUI

一个 macOS 原生的 Claude Code 多会话管理工具，支持终端集成、深色/浅色主题和中英文切换。

[English](README.md) | 中文

## 功能特性

- **多会话管理** — 侧边栏显示所有后台 agent 会话，按状态分组（等待输入、工作中、已完成、空闲）
- **新建会话** — 输入任务描述并选择工作目录，执行 `claude --bg "任务"` 创建后台会话
- **终端集成** — 每个会话拥有独立终端，基于 SwiftTerm PTY，运行 `claude attach <id>` 进入会话
- **拖拽文件** — 从 Finder 拖拽文件到终端，自动格式化为 `@/path/to/file`
- **自动同步** — 每 5 秒轮询 `claude agents --json` 刷新会话列表
- **主题切换** — 三种配色方案：基础（暗黑）、暗色（通透深色）、亮色（明亮浅色）
- **工作区挂载** — 支持挂载 VS Code 工作区配置，自动提取关联目录
- **中英文** — 支持中文/英文切换，所有 UI 文本均支持双语
- **快捷键** — `Cmd+R` 刷新会话列表，`Cmd+1~9` 快速切换会话
- **环境检测** — 启动时自动检测 Node.js、Claude CLI、登录状态
- **导出内容** — 右键点击会话可导出完整对话内容为 Markdown 文件

## 安装

从本仓库下载 `ClaudeGUI.app`，拖入应用程序文件夹即可使用。

> 需要 macOS 14.0+ 以及已安装 [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)。

## 前置条件

启动 ClaudeGUI 之前，请确保以下环境已就绪：

1. **Node.js** — Claude Code 是 Node.js CLI 工具，通过 [nvm](https://github.com/nvm-sh/nvm) 或 [Homebrew](https://brew.sh) 安装
   ```bash
   # 使用 nvm（推荐）
   nvm install --lts

   # 或使用 Homebrew
   brew install node
   ```

2. **Claude Code CLI** — 通过 npm 全局安装
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

3. **登录认证** — 首次使用前在终端运行 `claude` 完成登录
   ```bash
   claude
   ```
   会自动打开浏览器进行认证，完成后退出即可。

4. **验证安装** — 在终端确认以下命令正常工作：
   ```bash
   claude --version        # 输出版本号
   claude agents           # 显示 TUI 会话列表（无会话时为空）
   claude agents --json    # 输出 JSON 数组
   ```

如果 `claude` 命令找不到，应用会自动搜索 `~/.nvm/versions/node/*/bin/claude` 路径。

## 从源码构建

```bash
# 克隆仓库
git clone <repo-url>
cd ClaudeGUI

# 使用 Swift Package Manager 构建
swift build

# 创建 .app bundle
APP="ClaudeGUI.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/debug/ClaudeGUI "$APP/Contents/MacOS/"
cp Sources/ClaudeGUI/AppIcon.icns "$APP/Contents/Resources/"
cp -R .build/debug/SwiftTerm_SwiftTerm.bundle "$APP/Contents/Resources/"

# 或者直接用 Xcode 打开 Package.swift
open Package.swift
```

## 项目结构

```
ClaudeGUI/
├── Package.swift               # SPM 依赖配置（SwiftTerm）
├── Sources/ClaudeGUI/
│   ├── AppIcon.icns            # 应用图标
│   ├── Assets.xcassets/        # 资源目录（AppIcon）
│   ├── Info.plist              # 应用配置 + 图标引用
│   ├── ClaudeGUIApp.swift      # 应用入口
│   ├── Theme.swift             # 主题系统（基础/暗色/亮色）
│   ├── Localization.swift      # 中英文支持
│   ├── MainWindowController.swift  # 主窗口 + 终端管理
│   ├── Models/
│   │   ├── Session.swift       # 会话数据模型
│   │   └── SessionManager.swift    # 会话列表 + UserDefaults 持久化
│   ├── Views/
│   │   ├── ContentView.swift   # 根布局（侧边栏 + 终端）
│   │   ├── TabBarView.swift    # 侧边栏会话分组
│   │   ├── AboutView.swift     # 自定义关于窗口
│   │   ├── TerminalView.swift  # SwiftTerm SwiftUI 封装
│   │   ├── WelcomeView.swift   # 空状态欢迎页
│   │   └── DragDropTerminalView.swift  # 支持拖拽的终端
│   └── Services/
│       └── TerminalService.swift   # 终端生命周期管理
├── DESIGN.md                   # 设计规范文档
├── FEATURES.md                 # 功能概览
└── IMPLEMENTATION.md           # 实现参考
```

## 架构

```
MainWindowController (NSWindowController)
  └── NSSplitView
        ├── SidebarSessionView（SwiftUI，通过 NSHostingView 嵌入）
        │     ├── 主题切换 / 语言切换
        │     ├── 会话分组（可折叠）
        │     └── 新建会话按钮
        └── 终端容器
              ├── 概览终端（claude agents）
              └── 会话终端（claude attach <id>）
```

## TODO

- [x] **环境检测** — 启动时自动检测 Node.js、Claude Code CLI、登录状态，检测结果展示在 app 右上角
- [x] **工作区** — 引入工作区（Workspace）概念，按工作目录分组，每个工作区下独立管理四个状态分组（等待输入、工作中、已完成、空闲），每个状态组下再挂载具体会话
- [x] **VS Code 工作区挂载** — 支持挂载 `.code-workspace` 文件，自动提取关联目录
- [x] **双击复制路径** — 双击侧边栏目录路径可复制到剪贴板，带吐司提示
- [x] **导出会话内容** — 右键点击会话选择「导出内容」，从 `~/.claude/projects/` 读取完整对话记录并保存为 Markdown 文件

## 许可证

MIT
