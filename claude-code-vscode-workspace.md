# Claude Code 与 VS Code 工作区集成说明

## 1. VS Code 工作区配置文件

工作区配置文件以 `.code-workspace` 结尾，使用 JSON 格式存储。

**示例路径**: `/Users/xuzhaowen/code/shenzhou/cursor/V3.17.97/Shenzhou-Knowledge-Base.code-workspace`

**文件格式**:
```json
{
  "folders": [
    {
      "name": "V3.17.97-order-list-search-ctrl",
      "path": "../../Shenzhou-Knowledge-Base/version-docs/V3.17.97-order-list-search-ctrl"
    },
    {
      "name": "Shenzhou-New-Admin-Web",
      "path": "../../Shenzhou-New-Admin-Web"
    },
    {
      "path": "../../Shenzhou-Knowledge-Base"
    }
  ]
}
```

**字段说明**:
- `name`: 工作区中显示的文件夹名称（可选）
- `path`: 文件夹路径（相对于 .code-workspace 文件的位置）

## 2. Claude Code 如何获取工作区信息

VS Code 扩展通过**命令行参数** `--add-dir` 将额外的工作目录传递给 Claude Code。

**工作流程**:
1. VS Code 扩展通过 `vscode.workspace.workspaceFolders` API 读取 `.code-workspace` 文件
2. 启动 Claude Code 进程时，使用 `--add-dir` 参数添加额外的工作区文件夹
3. Claude Code 将这些信息显示在系统环境上下文中

**进程参数示例**:
```bash
claude --add-dir /path/to/folder1 --add-dir /path/to/folder2
```

## 3. 会话信息查看

### 3.1 获取 Session ID

**方法 1**: 通过环境变量
```bash
env | grep CLAUDE_CODE_SESSION_ID
```
输出示例: `CLAUDE_CODE_SESSION_ID=2a7e0a0c-e650-4853-a68f-7aff1b4ed730`

**方法 2**: 查看所有 Claude 相关环境变量
```bash
env | grep -i claude
```

### 3.2 查看当前会话进程

```bash
ps aux | grep claude | grep -v grep
```

**输出字段说明**:
- `pid`: 进程 ID
- `cwd`: 工作目录
- `kind`: 会话类型（interactive/background）
- `startedAt`: 启动时间戳
- `sessionId`: 会话唯一标识
- `name`: 会话名称（可选）
- `status`: 状态（idle/running）

### 3.3 会话对比示例

| 对比项 | 当前会话 | 另一个会话 |
|--------|----------|------------|
| PID | 33913 | 77512 |
| 工作目录 | `Shenzhou-Knowledge-Base/version-docs/V3.17.97-order-list-search-ctrl` | `xiaomimimo_used` |
| 类型 | interactive（交互式） | background（后台） |
| Session ID | `2a7e0a0c-e650-4853-a68f-7aff1b4ed730` | `9ead7aa4-11c1-4656-83c0-129c77c58497` |
| 项目 | 神州知识库版本文档 | 小米文档 |

**不同原因**:
1. 不同的工作目录 - 每个会话启动时绑定到各自的目录
2. 不同的项目上下文 - 一个在神州项目，一个在小米项目
3. 独立进程 - 每个会话是独立的 Claude Code 进程，有自己的会话ID和上下文

## 4. 关键环境变量

| 变量名 | 说明 |
|--------|------|
| `CLAUDE_CODE_SESSION_ID` | 当前会话的唯一标识 |
| `CLAUDE_CODE_ENTRYPOINT` | 启动入口（如 `claude-vscode`） |
| `CLAUDE_CODE_EXECPATH` | Claude 可执行文件路径 |
| `CLAUDECODE` | 是否为 Claude Code 环境（1=是） |
| `VSCODE_CWD` | VS Code 工作目录 |

## 5. Claude Code 扩展路径

**扩展安装路径**: `~/.vscode/extensions/anthropic.claude-code-2.1.145-darwin-arm64/`

**关键文件**:
- `extension.js`: 扩展主逻辑
- `package.json`: 扩展配置
- `resources/native-binary/claude`: Claude 原生二进制文件

## 6. ClaudeGUI 工作区挂载

ClaudeGUI 支持直接挂载 `.code-workspace` 文件，无需通过 VS Code 扩展。

### 6.1 挂载工作区

1. 点击侧边栏顶部的挂载按钮（`link.badge.plus` 图标）
2. 选择一个 `.code-workspace` 文件
3. 程序解析文件中的 `folders` 数组，将第一个目录作为主目录，其余作为关联目录
4. 关联目录通过 `--add-dir` 参数传递给新创建的 Claude Code 会话

**注意**：挂载工作区前，需要先存在一个工作目录匹配的会话（即 `folders[0].path` 对应的目录）。

### 6.2 取消挂载

展开已挂载的工作区，点击展开区域内的"取消挂载工作区"按钮即可移除工作区配置。取消挂载后：

- 该工作区的关联目录不再显示
- 新建会话时不再自动添加 `--add-dir` 参数
- 不影响已有的正在运行的会话

### 6.3 配置变更提示

如果重新挂载了不同的 `.code-workspace` 文件到同一工作区，会显示黄色三角提示"工作区配置已变更，请新建会话"。这是因为已有会话的 `--add-dir` 参数在创建时已固定，需要新建会话才能使用新的关联目录。

### 6.4 数据存储

工作区配置持久化在 UserDefaults（key: `claudeGUI_workspaceConfigs`），重启应用后自动恢复。数据结构：

```json
{
  "/path/to/primaryDir": {
    "filePath": "/path/to/workspace.code-workspace",
    "primaryDir": "/path/to/primaryDir",
    "relatedDirs": ["/path/to/dir2", "/path/to/dir3"],
    "needsRestart": false
  }
}
```

---
*记录时间: 2026-05-23*
