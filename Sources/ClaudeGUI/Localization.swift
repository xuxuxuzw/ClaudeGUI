import Foundation

enum Language: String {
    case chinese = "zh"
    case english = "en"
}

class Localization: ObservableObject {
    static let shared = Localization()

    @Published var current: Language = .chinese

    private init() {}

    func toggle() {
        current = current == .chinese ? .english : .chinese
    }
}

// MARK: - Localized Strings

enum L10n {
    // Sidebar
    static var agents: String {
        Localization.shared.current == .chinese ? "智能体" : "Agents"
    }
    static var allSessions: String {
        Localization.shared.current == .chinese ? "所有会话" : "All Sessions"
    }
    static var newSession: String {
        Localization.shared.current == .chinese ? "新建会话" : "New Session"
    }
    static var newSessionPrompt: String {
        Localization.shared.current == .chinese ? "请输入任务描述：" : "Enter task description:"
    }
    static var newSessionPlaceholder: String {
        Localization.shared.current == .chinese ? "例如：修复 auth 模块里所有失败的单元测试" : "e.g.: Fix all failing unit tests in auth module"
    }
    static var selectDirectory: String {
        Localization.shared.current == .chinese ? "选择工作目录" : "Select Working Directory"
    }
    static var selectDirectoryPrompt: String {
        Localization.shared.current == .chinese ? "选择新会话的工作目录" : "Choose a working directory for the new session"
    }
    static var workingDirectory: String {
        Localization.shared.current == .chinese ? "工作目录" : "Working Directory"
    }
    static var browse: String {
        Localization.shared.current == .chinese ? "浏览…" : "Browse…"
    }
    static var cancel: String {
        Localization.shared.current == .chinese ? "取消" : "Cancel"
    }
    static var createSession: String {
        Localization.shared.current == .chinese ? "创建会话" : "Create Session"
    }
    static var awaitingInput: String {
        Localization.shared.current == .chinese ? "等待输入" : "Awaiting Input"
    }
    static var working: String {
        Localization.shared.current == .chinese ? "工作中" : "Working"
    }
    static var completed: String {
        Localization.shared.current == .chinese ? "已完成" : "Completed"
    }
    static var idle: String {
        Localization.shared.current == .chinese ? "空闲" : "Idle"
    }
    static var noSessions: String {
        Localization.shared.current == .chinese ? "暂无会话" : "No sessions"
    }
    static var workspaces: String {
        Localization.shared.current == .chinese ? "工作区" : "Workspaces"
    }
    static var noWorkspaces: String {
        Localization.shared.current == .chinese ? "暂无工作区" : "No workspaces"
    }

    // Environment Check
    static var envCheck: String {
        Localization.shared.current == .chinese ? "环境检测" : "Environment"
    }
    static var nodeJs: String {
        "Node.js"
    }
    static var claudeCli: String {
        "Claude CLI"
    }
    static var loginStatus: String {
        Localization.shared.current == .chinese ? "登录状态" : "Login"
    }
    static var envOk: String {
        Localization.shared.current == .chinese ? "正常" : "OK"
    }
    static var envFail: String {
        Localization.shared.current == .chinese ? "未检测到" : "Not found"
    }
    static var checking: String {
        Localization.shared.current == .chinese ? "检测中…" : "Checking…"
    }
    static func agentCount(_ count: Int) -> String {
        Localization.shared.current == .chinese ? "\(count) 个智能体" : "\(count) agent\(count == 1 ? "" : "s")"
    }

    // Context Menu
    static var stopSession: String {
        Localization.shared.current == .chinese ? "停止会话" : "Stop Session"
    }
    static var deleteSession: String {
        Localization.shared.current == .chinese ? "删除会话" : "Delete Session"
    }

    // Welcome
    static var welcomeSubtitle: String {
        Localization.shared.current == .chinese ? "管理多个 Claude Code 会话\n使用类似浏览器的标签页" : "Manage multiple Claude Code sessions\nwith browser-like tabs"
    }
    static var newTab: String {
        Localization.shared.current == .chinese ? "新建标签" : "New Tab"
    }
    static var closeTab: String {
        Localization.shared.current == .chinese ? "关闭标签" : "Close Tab"
    }
    static var switchTab: String {
        Localization.shared.current == .chinese ? "切换标签" : "Switch Tab"
    }

    // Menu
    static var language: String {
        Localization.shared.current == .chinese ? "语言" : "Language"
    }
    static var switchToEnglish: String {
        "English"
    }
    static var switchToChinese: String {
        "中文"
    }

    static var permissionMode: String {
        Localization.shared.current == .chinese ? "切换权限模式" : "Cycle Permission Mode"
    }
    static var permissionModeDesc: String {
        Localization.shared.current == .chinese ? "控制 Claude 执行操作前是否需要确认" : "Control whether Claude needs confirmation before actions"
    }
}
