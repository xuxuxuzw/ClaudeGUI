# ClaudeGUI 项目规则

## 构建流程

### SwiftTerm 本地依赖

项目使用本地 SwiftTerm 包（`./LocalSwiftTerm`），已包含自定义补丁：禁止向子进程发送鼠标移动事件，防止 claude CLI 在鼠标悬停 URL 时自动打开浏览器。

补丁已提交到 `LocalSwiftTerm` 的 `claudegui-patch` 分支，无需每次手动应用。

### Release 构建步骤

```bash
# 1. 编译
xcodebuild -scheme ClaudeGUI -configuration Release clean build

# 2. 找到 DerivedData 路径
DERIVED=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -name "ClaudeGUI-*" -type d | head -1)

# 3. 复制 app 到项目根目录（必须先删除再 ditto，不能用 cp -R）
rm -rf ./ClaudeGUI.app
ditto "$DERIVED/Build/Products/Release/ClaudeGUI.app" ./ClaudeGUI.app

# 4. 修复图标（Info.plist 可能缺少 CFBundleIconFile）
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" ./ClaudeGUI.app/Contents/Info.plist 2>/dev/null || true

# 5. 刷新 LaunchServices 缓存
touch ./ClaudeGUI.app
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R ./ClaudeGUI.app
```

### 一键构建脚本

```bash
#!/bin/bash
set -e
cd "$(dirname "$0")"

# Build
xcodebuild -scheme ClaudeGUI -configuration Release clean build

# Find DerivedData
DERIVED=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -name "ClaudeGUI-*" -type d | head -1)

# Copy app
rm -rf ./ClaudeGUI.app
ditto "$DERIVED/Build/Products/Release/ClaudeGUI.app" ./ClaudeGUI.app

# Fix icon
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" ./ClaudeGUI.app/Contents/Info.plist 2>/dev/null || true

# Refresh cache
touch ./ClaudeGUI.app
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R ./ClaudeGUI.app

echo "Build complete: ./ClaudeGUI.app"
```

## 注意事项

- **不要用 `cp -R` 覆盖 app bundle**：macOS bundle 是目录结构，`cp -R` 可能只替换部分文件。用 `rm -rf` + `ditto`
- **Info.plist 图标问题**：xcodebuild 可能不自动写入 `CFBundleIconFile`，需要手动添加
- **LocalSwiftTerm 目录**：包含项目自定义补丁，不要删除。如需升级 SwiftTerm，在 `LocalSwiftTerm` 目录中 `git fetch upstream && git rebase` 后重新应用补丁

## 项目结构

```
ClaudeGUI/
├── LocalSwiftTerm/                 # 本地 SwiftTerm 包（含自定义补丁）
├── Sources/ClaudeGUI/
│   ├── ClaudeGUIApp.swift          # 入口，AppDelegate
│   ├── MainWindowController.swift  # 主窗口控制器（滚轮拦截、快捷键等）
│   ├── Models/
│   │   ├── PermissionMode.swift    # 权限模式枚举
│   │   └── Localization.swift      # 本地化字符串
│   └── Views/
│       ├── DragDropTerminalView.swift  # 终端视图（拖拽文件支持）
│       ├── TabBarView.swift            # 侧边栏
│       └── TerminalView.swift          # SwiftUI 包装器（当前未使用）
├── Package.swift                    # SPM 配置（依赖本地 SwiftTerm）
└── SESSION_SUMMARY.md               # 会话记录
```

## 已知问题与修复

| 问题 | 根因 | 修复位置 |
|------|------|---------|
| 鼠标悬停 URL 自动打开浏览器 | claude CLI 开启鼠标追踪，收到坐标后自己执行 `open URL` | LocalSwiftTerm `MacTerminalView.swift` mouseMoved |
| 终端无法滚动 | claude CLI 使用 alternate screen buffer，scrollback 为 nil | MainWindowController handleScrollWheel |
| 终端初始化零尺寸 | terminalContainer.bounds 在 init 时为 .zero | MainWindowController makeTerminal 兜底帧 |
| 无法选中文字 | allowMouseReporting=true 导致鼠标事件转发给 PTY | DragDropTerminalView allowMouseReporting=false |
