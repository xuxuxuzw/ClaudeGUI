# ClaudeGUI 设计规范

> 本文档定义了 ClaudeGUI 的视觉设计系统，供开发和迭代时参考。
> 所有颜色值均定义在 `Sources/ClaudeGUI/Theme.swift` 中。

---

## 1. 设计原则

- **暗黑优先**：所有界面元素以暗黑模式为基准设计，不考虑亮色主题
- **多主题支持**：通过 `ThemeManager` 支持 Basic / Clear Dark 两种配色方案切换
- **信息密度**：侧边栏紧凑排列，终端区域最大化
- **状态可见**：通过颜色和图标清晰区分会话状态
- **一致性**：所有可交互元素使用统一的圆角、间距和颜色

---

## 2. 色彩系统

### 2.1 背景色（由深到浅）

| Token | 值 | 用途 |
|-------|-----|------|
| `bgDeep` | `Color(white: 0.08)` `#141414` | 终端背景 |
| `bgBase` | `Color(white: 0.10)` `#1A1A1A` | 侧边栏、对话框背景 |
| `bgSurface` | `Color(white: 0.12)` `#1F1F1F` | 卡片、输入框背景 |
| `bgElevated` | `Color(white: 0.15)` `#262626` | 悬停态、按钮背景 |

层级关系：`bgDeep < bgBase < bgSurface < bgElevated`

### 2.2 边框色

| Token | 值 | 用途 |
|-------|-----|------|
| `borderSubtle` | `Color(white: 0.18)` `#2E2E2E` | 细分割线 |
| `borderDefault` | `Color(white: 0.22)` `#383838` | 输入框、卡片边框 |

### 2.3 文字色

| Token | 值 | 用途 |
|-------|-----|------|
| `textPrimary` | `Color(white: 0.92)` `#EBEBEB` | 标题、正文、输入文字 |
| `textSecondary` | `Color(white: 0.55)` `#8C8C8C` | 副标题、描述文字 |
| `textMuted` | `Color(white: 0.40)` `#666666` | placeholder、辅助信息、shortId |

层级关系：`textPrimary > textSecondary > textMuted`

### 2.4 状态色

| 状态 | 颜色 | 用途 |
|------|------|------|
| 等待输入 (waiting) | `.green` | 状态圆点、分组标题 |
| 工作中 (working) | `.orange` | 状态圆点、分组标题 |
| 已完成 (completed) | `.blue` | 状态圆点、分组标题 |
| 空闲 (idle) | `.gray` | 状态圆点、分组标题 |

### 2.5 强调色

| Token | 值 | 用途 |
|-------|-----|------|
| `accentColor` | 系统 `.accentColor` | 按钮、活跃指示条、图标 |
| `accentBg` | `.accentColor.opacity(0.10)` | 活跃会话行背景 |
| `accentBgHover` | `.accentColor.opacity(0.15)` | 强调悬停态 |

### 2.6 主题配色方案

应用支持两种配色方案，通过侧边栏的 `Basic` / `Clear` 按钮切换，选择通过 UserDefaults 持久化。

#### Basic（默认）

标准暗黑风格，背景不透明，对比度适中。

| Token | 值 |
|-------|-----|
| bgDeep | `Color(white: 0.08)` |
| bgBase | `Color(white: 0.10)` |
| bgSurface | `Color(white: 0.12)` |
| bgElevated | `Color(white: 0.15)` |
| borderSubtle | `Color(white: 0.18)` |
| borderDefault | `Color(white: 0.22)` |
| textPrimary | `Color(white: 0.92)` |
| textSecondary | `Color(white: 0.55)` |
| textMuted | `Color(white: 0.40)` |
| termBg | `#19191E` (6554,6554,7864) |
| termFg | `#969696` (58982,58982,58982) |

#### Clear Dark

通透深色风格，背景带透明度，边框更亮且半透明，文字整体稍亮。

| Token | 值 |
|-------|-----|
| bgDeep | `Color(white: 0.06).opacity(0.92)` |
| bgBase | `Color(white: 0.08).opacity(0.88)` |
| bgSurface | `Color(white: 0.12).opacity(0.80)` |
| bgElevated | `Color(white: 0.16).opacity(0.75)` |
| borderSubtle | `Color(white: 0.22).opacity(0.50)` |
| borderDefault | `Color(white: 0.28).opacity(0.50)` |
| textPrimary | `Color(white: 0.95)` |
| textSecondary | `Color(white: 0.60)` |
| textMuted | `Color(white: 0.48)` |
| termBg | `#141420` (5140,5140,8192) |
| termFg | `#A0A0A8` (62258,62258,64250) |

#### Clear Light

明亮浅色风格，取自 macOS Terminal Clear Light 配色，白色背景，深蓝灰文字。

| Token | 值 |
|-------|-----|
| bgDeep | `Color(red: 0.96, green: 0.97, blue: 0.98)` |
| bgBase | `Color(red: 0.98, green: 0.98, blue: 0.99)` |
| bgSurface | `Color.white` |
| bgElevated | `Color(red: 0.93, green: 0.94, blue: 0.96)` |
| borderSubtle | `Color(red: 0.88, green: 0.90, blue: 0.92)` |
| borderDefault | `Color(red: 0.82, green: 0.85, blue: 0.88)` |
| textPrimary | `Color(red: 0.19, green: 0.24, blue: 0.27)` `#303c43` |
| textSecondary | `Color(red: 0.42, green: 0.48, blue: 0.53)` |
| textMuted | `Color(red: 0.56, green: 0.60, blue: 0.64)` |
| termBg | `#ffffff` (65535,65535,65535) |
| termFg | `#3a4850` (15038,18498,20774) |

---

## 3. 字体规范

### 3.1 字号与字重

| 用途 | 字号 | 字重 | 字体 |
|------|------|------|------|
| 对话框标题 | 16pt | `.semibold` | 系统默认 |
| 区域标题（代理） | 14pt | `.bold` | 系统默认 |
| 欢迎页大标题 | 28pt | `.bold` | 系统默认 |
| 正文 / 输入文字 | 13pt | `.regular` | 系统默认 |
| 按钮文字 | 12-14pt | `.medium` / `.semibold` | 系统默认 |
| 会话名 | 12pt | `.regular` / `.semibold` | 系统默认 |
| shortId | 11pt | `.medium` | `.monospaced` |
| 辅助信息 | 10-11pt | `.regular` | 系统默认 |
| 快捷键标签 | 11pt | `.medium` | `.monospaced` |

### 3.2 规则

- 等宽字体仅用于：shortId、快捷键标签、终端内容
- 活跃状态会话名使用 `.semibold`，非活跃使用 `.regular`
- 所有文字使用 `.foregroundStyle()` 设置颜色，不使用默认黑色

---

## 4. 间距系统

| Token | 值 | 用途 |
|-------|-----|------|
| `xs` | 4pt | 最小内边距 |
| `sm` | 6pt | 图标与文字间距 |
| `md` | 8pt | 列表行内间距、分组内边距 |
| `lg` | 12pt | 区域分隔 |
| `xl` | 16pt | 侧边栏水平内边距 |
| `xxl` | 24pt | 对话框内边距、大间距 |

### 4.1 常用间距组合

- 侧边栏头部：水平 16pt，垂直 12pt
- 会话行：水平 8pt（内容区）+ 8pt（外边距），垂直 5-8pt
- 对话框内容：内边距 24pt，元素间距 16-20pt
- 分组标题：垂直 4pt

---

## 5. 圆角系统

| Token | 值 | 用途 |
|-------|-----|------|
| `sm` | 4pt | 快捷键标签、计数标签 |
| `md` | 6pt | 会话行背景 |
| `lg` | 8pt | 输入框、按钮 |
| `xl` | 10pt | 欢迎页按钮 |

### 5.1 规则

- 所有可交互卡片/行：6pt 圆角
- 输入框和按钮：8pt 圆角（对话框中）或 10pt（欢迎页）
- 小标签/徽章：4pt 圆角

---

## 6. 组件规范

### 6.1 侧边栏

- 背景：`bgBase`
- 宽度：220pt（可拖拽，范围 180-300pt）
- 分隔线：`AppTheme.divider` overlay（暗色主题用白色 0.08，亮色主题用黑色 0.08）
- 头部按钮区：左侧标题"代理"，右侧主题切换按钮 + 语言切换按钮

#### 主题切换按钮
- 点击循环切换：基础(Basic) → 暗色(Dark) → 亮色(Light)
- 按钮文字跟随当前语言（中文显示"基础/暗色/亮色"，英文显示"Basic/Dark/Light"）
- 样式：`accentColor` 文字，`accentBg` 背景，4pt 圆角
- 选择通过 UserDefaults 持久化

#### 会话行
- 高度：约 32pt（垂直 padding 5pt + 内容）
- 默认背景：`.clear`
- 悬停背景：`AppTheme.hoverBg`
- 活跃背景：`accentBg` + 右侧 3pt 宽蓝色竖条
- 活跃状态圆点：8pt，颜色 = 状态色
- 非活跃状态圆点：6pt，颜色 = 状态色

#### 分组标题
- 高度：约 24pt
- 左侧 8pt 状态色圆点
- 右侧计数标签：`bgSurface` 背景，4pt 圆角
- 展开/收起箭头：9pt，`textMuted` 颜色，带旋转动画

### 6.2 新建会话对话框

- 宽度：440pt
- 背景：`bgBase`
- 内边距：24pt
- 标题栏：透明（`titlebarAppearsTransparent`），可拖拽背景

#### 输入框
- 使用 `NSTextField`（NSViewRepresentable），非 SwiftUI TextField
- 背景：`bgSurface`
- 边框：`borderDefault`，1pt
- 圆角：8pt
- 文字颜色：`textPrimary`
- placeholder 颜色：`textMuted`
- 内边距：10pt

#### 目录选择器
- 外观同输入框
- 文件夹图标：`accentColor.opacity(0.7)`
- 路径文字：等宽 12pt，`textPrimary.opacity(0.8)`
- "浏览" 按钮：`accentColor` 文字

#### 按钮
- 取消按钮：`bgElevated` 背景，`borderDefault` 边框，`textSecondary` 文字
- 确认按钮：`accentColor` 背景，白色文字
- 圆角：8pt
- 禁用态：opacity 0.5

### 6.3 欢迎页

- 背景：`bgBase`
- 图标：80pt 圆形，`accentColor.opacity(0.12)` 背景，36pt SF Symbol
- 标题：28pt bold，`textPrimary`
- 副标题：14pt，`textSecondary`，4pt 行间距
- 快捷键提示：11pt，`textSecondary`，`bgElevated` 背景

### 6.4 终端

- 背景色：SwiftTerm `Color(red: 6554, green: 6554, blue: 7864)` ≈ `#101013`
- 前景色：SwiftTerm `Color(red: 58982, green: 58982, blue: 58982)` ≈ `#959595`

---

## 7. 图标

- 全部使用 SF Symbols
- 尺寸范围：8pt（状态圆点）~ 36pt（欢迎页图标）
- 侧边栏图标：12-13pt
- 按钮图标：10-13pt

常用图标：
| 用途 | 图标名 |
|------|--------|
| 新建 | `plus` / `plus.circle.fill` |
| 关闭 | `xmark` |
| 终端 | `terminal.fill` / `terminal` |
| 概览 | `square.grid.2x2` |
| 播放 | `play.fill` |
| 停止 | `stop.circle` |
| 删除 | `trash` |
| 文件夹 | `folder.fill` |
| 等待 | `clock` |
| 工作 | `gear` |
| 完成 | `checkmark.circle` |
| 空闲 | `moon` |

---

## 8. 动画

| 场景 | 动画 |
|------|------|
| 侧边栏悬停 | `.easeInOut(duration: 0.1)` |
| 分组展开/收起箭头旋转 | `.rotationEffect` + 默认动画 |
| 按钮禁用态 | `.opacity()` 无动画 |

原则：动画时长 ≤ 0.1s，仅用于状态反馈，不做装饰性动画。

---

## 9. 布局

```
+---------------------------+
|        主窗口              |
|  +--------+  +----------+ |
|  | 侧边栏  |  | 终端区域  | |
|  | 220pt   |  | flex     | |
|  +--------+  +----------+ |
+---------------------------+
```

- 主窗口最小尺寸：700 x 400pt
- 默认尺寸：1100 x 700pt
- 分栏：`HSplitView`，侧边栏宽度 180-300pt
- 终端区域：`maxWidth: .infinity, maxHeight: .infinity`

---

## 10. 主题系统

- **ThemeManager 单例**：`ThemeManager.shared` 管理当前配色方案，通过 `@Published var current` 驱动 SwiftUI 刷新
- **AppTheme 计算属性**：所有颜色通过 `AppTheme.xxx` 静态计算属性获取，内部读取 `ThemeManager.shared.current` 返回对应值
- **持久化**：主题选择通过 UserDefaults（key: `"claudeGUI_colorScheme"`）持久化
- **终端颜色同步**：`AppTheme.termBg` / `AppTheme.termFg` / `AppTheme.termContainerBg` 提供终端专用颜色
- **新增主题时**：在 `ColorScheme` 枚举中添加 case，在 `AppTheme` 每个计算属性的 switch 中添加对应色值

---

## 11. 暗黑模式注意事项

- **禁止使用默认黑色文字**：所有 `.foregroundStyle()` 必须显式设置为 `textPrimary` / `textSecondary` / `textMuted`
- **输入框必须使用 ThemedTextField**：SwiftUI 的 `TextField` + `.textFieldStyle(.plain)` 在暗黑模式下 placeholder 不可控，必须使用 `NSViewRepresentable` 包装的 `NSTextField`
- **分隔线使用 overlay**：`Divider().overlay(Color.white.opacity(0.08))`，避免系统默认色
- **悬停态使用白色透明度**：`Color.white.opacity(0.05)`，不使用系统 `.hover` 色
