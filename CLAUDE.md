# ClaudeGUI 项目规则

## 构建流程

### 前提：SwiftTerm 补丁

项目依赖 SwiftTerm 包，但对其源码有本地修改（禁止向子进程发送鼠标移动事件，防止 claude CLI 自动打开 URL）。每次 SPM 重新 checkout 包后，补丁会丢失，必须重新应用。

**补丁位置**：`MacTerminalView.swift` 的 `mouseMoved` 方法

**原始代码**：
```swift
if terminal.mouseMode.sendMotionEvent() {
    let flags = encodeMouseEvent(with: event, overwriteRelease: true)
    terminal.sendMotion(buttonFlags: flags, x: hit.grid.col, y: hit.grid.row, pixelX: hit.pixels.col, pixelY: hit.pixels.row)
}
```

**替换为**：
```swift
// Disabled: sending mouse motion events to the child process causes
// the claude CLI to auto-open URLs when the mouse hovers over them.
// if terminal.mouseMode.sendMotionEvent() {
//     let flags = encodeMouseEvent(with: event, overwriteRelease: true)
//     terminal.sendMotion(buttonFlags: flags, x: hit.grid.col, y: hit.grid.row, pixelX: hit.pixels.col, pixelY: hit.pixels.row)
// }
```

### Release 构建步骤

```bash
# 1. 清理旧构建产物
rm -rf build

# 2. 用 xcodebuild 编译（使用默认 DerivedData 路径，不要用 -derivedDataPath）
xcodebuild -scheme ClaudeGUI -configuration Release clean build

# 3. 找到 DerivedData 路径（每次可能不同）
DERIVED=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -name "ClaudeGUI-*" -type d | head -1)

# 4. 对 SwiftTerm 应用补丁
SWIFTTERM_FILE="$DERIVED/SourcePackages/checkouts/SwiftTerm/Sources/SwiftTerm/Mac/MacTerminalView.swift"
chmod u+w "$SWIFTTERM_FILE"
# 用 sed 替换（见下方完整命令）

# 5. 重新编译（增量编译，只重编 SwiftTerm）
xcodebuild -scheme ClaudeGUI -configuration Release build

# 6. 复制 app 到项目根目录（必须先删除再 ditto，不能用 cp -R）
rm -rf ./ClaudeGUI.app
ditto "$DERIVED/Build/Products/Release/ClaudeGUI.app" ./ClaudeGUI.app

# 7. 修复图标（Info.plist 可能缺少 CFBundleIconFile）
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" ./ClaudeGUI.app/Contents/Info.plist 2>/dev/null || true

# 8. 刷新 LaunchServices 缓存
touch ./ClaudeGUI.app
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R ./ClaudeGUI.app
```

### 一键构建脚本

```bash
#!/bin/bash
set -e
cd "$(dirname "$0")"

# Clean
rm -rf build

# First build to let SPM checkout packages
xcodebuild -scheme ClaudeGUI -configuration Release clean build

# Find DerivedData
DERIVED=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -name "ClaudeGUI-*" -type d | head -1)
SWIFTTERM_FILE="$DERIVED/SourcePackages/checkouts/SwiftTerm/Sources/SwiftTerm/Mac/MacTerminalView.swift"

# Apply SwiftTerm patch: disable mouse motion events to child process
chmod u+w "$SWIFTTERM_FILE"
sed -i '' 's/        if terminal\.mouseMode\.sendMotionEvent() {/        \/\/ Disabled: sending mouse motion events to the child process causes\n        \/\/ the claude CLI to auto-open URLs when the mouse hovers over them.\n        \/\/ if terminal.mouseMode.sendMotionEvent() {/' "$SWIFTTERM_FILE"
sed -i '' 's/            let flags = encodeMouseEvent(with: event, overwriteRelease: true)/            \/\/ let flags = encodeMouseEvent(with: event, overwriteRelease: true)/' "$SWIFTTERM_FILE"
sed -i '' 's/            terminal\.sendMotion(buttonFlags: flags, x: hit\.grid\.col, y: hit\.grid\.row, pixelX: hit\.pixels\.col, pixelY: hit\.pixels\.row)/            \/\/ terminal.sendMotion(buttonFlags: flags, x: hit.grid.col, y: hit.grid.row, pixelX: hit.pixels.col, pixelY: hit.pixels.row)/' "$SWIFTTERM_FILE"
sed -i '' 's/        }$/        \/\/ }/' "$SWIFTTERM_FILE"

# Rebuild with patched SwiftTerm
xcodebuild -scheme ClaudeGUI -configuration Release build

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

- **不要用 `-derivedDataPath`**：会导致 SPM 在新路径重新 checkout 包，补丁需要重新应用
- **不要用 `cp -R` 覆盖 app bundle**：macOS bundle 是目录结构，`cp -R` 可能只替换部分文件。用 `rm -rf` + `ditto`
- **清缓存后必须重新应用 SwiftTerm 补丁**：`clean` 或删除 DerivedData 后 SPM 会重新 checkout 原始代码
- **Info.plist 图标问题**：xcodebuild 可能不自动写入 `CFBundleIconFile`，需要手动添加
- **Xcode GUI 编译 vs xcodebuild**：Xcode GUI 使用固定的 DerivedData 路径，补丁只需应用一次；xcodebuild 可能创建新的 DerivedData 路径

## 项目结构

```
ClaudeGUI/
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
├── Package.swift                    # SPM 配置（依赖 SwiftTerm）
└── SESSION_SUMMARY.md               # 会话记录
```

## 已知问题与修复

| 问题 | 根因 | 修复位置 |
|------|------|---------|
| 鼠标悬停 URL 自动打开浏览器 | claude CLI 开启鼠标追踪，收到坐标后自己执行 `open URL` | SwiftTerm `MacTerminalView.swift` mouseMoved |
| 终端无法滚动 | claude CLI 使用 alternate screen buffer，scrollback 为 nil | MainWindowController handleScrollWheel |
| 终端初始化零尺寸 | terminalContainer.bounds 在 init 时为 .zero | MainWindowController makeTerminal 兜底帧 |
| 无法选中文字 | allowMouseReporting=true 导致鼠标事件转发给 PTY | DragDropTerminalView allowMouseReporting=false |
