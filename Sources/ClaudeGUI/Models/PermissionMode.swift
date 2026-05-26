import Foundation

enum PermissionMode: String, CaseIterable, Codable {
    case `default`
    case acceptEdits
    case plan
    case auto
    case bypassPermissions

    var cliFlag: String {
        "--permission-mode \(rawValue)"
    }

    var displayName: String {
        let isCN = Localization.shared.current == .chinese
        switch self {
        case .default:            return isCN ? "默认 (Default)" : "Default"
        case .acceptEdits:        return isCN ? "接受编辑 (AcceptEdits)" : "Accept Edits"
        case .plan:               return isCN ? "规划模式 (Plan)" : "Plan"
        case .auto:               return isCN ? "自动模式 (Auto)" : "Auto"
        case .bypassPermissions:  return isCN ? "绕过权限 (Bypass)" : "Bypass Permissions"
        }
    }

    var description: String {
        let isCN = Localization.shared.current == .chinese
        switch self {
        case .default:
            return isCN ? "读取文件不需要确认，修改文件需要确认" : "Read files freely, confirm edits"
        case .acceptEdits:
            return isCN ? "文件编辑不需要确认，执行命令仍需确认" : "Edits auto-approved, commands need confirmation"
        case .plan:
            return isCN ? "只能读取文件，不能编辑，适合探索和规划" : "Read-only, for exploration and planning"
        case .auto:
            return isCN ? "后台分类器自动评估安全性" : "Background classifier evaluates safety"
        case .bypassPermissions:
            return isCN ? "跳过所有安全检查，仅限隔离环境使用" : "Skip all checks, isolated environments only"
        }
    }

    static func persistedDefault() -> PermissionMode {
        guard let raw = UserDefaults.standard.string(forKey: "claudeGUI_defaultPermissionMode"),
              let mode = PermissionMode(rawValue: raw) else {
            return .default
        }
        return mode
    }

    func persistAsDefault() {
        UserDefaults.standard.set(rawValue, forKey: "claudeGUI_defaultPermissionMode")
    }
}
