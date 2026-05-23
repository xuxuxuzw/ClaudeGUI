import Foundation
import Combine

struct Workspace: Identifiable {
    let path: String       // workingDirectory full path, serves as unique ID
    var name: String       // lastPathComponent for display
    var sessions: [Session]
    var vscodeWorkspacePath: String?  // path to .code-workspace file
    var relatedDirs: [String]          // other folders from the workspace config
    var needsRestart: Bool = false     // config changed, new session needed

    var id: String { path }
}

final class SessionManager: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var activeSessionId: UUID?
    @Published var activeWorkspacePath: String?

    private let sessionsKey = "claudeGUI_sessions"
    private let workspaceConfigsKey = "claudeGUI_workspaceConfigs"

    /// Persisted workspace configs: [workspacePath: VSCodeWorkspaceConfig]
    private var workspaceConfigs: [String: VSCodeWorkspaceConfig] = [:]

    init() {
        loadSessions()
        loadWorkspaceConfigs()
    }

    // MARK: - Workspace Grouping

    var workspaces: [Workspace] {
        Dictionary(grouping: sessions, by: \.workingDirectory)
            .map { key, value in
                let url = URL(fileURLWithPath: key)
                let name = url.lastPathComponent.isEmpty ? key : url.lastPathComponent
                let config = workspaceConfigs[key]
                return Workspace(
                    path: key,
                    name: name,
                    sessions: value,
                    vscodeWorkspacePath: config?.filePath,
                    relatedDirs: config?.relatedDirs ?? [],
                    needsRestart: config?.needsRestart ?? false
                )
            }
            .sorted { $0.name < $1.name }
    }

    // MARK: - Session CRUD

    @discardableResult
    func createSession(name: String = "New Session", workingDirectory: String? = nil) -> Session {
        let dir = workingDirectory ?? FileManager.default.homeDirectoryForCurrentUser.path
        let session = Session(name: name, workingDirectory: dir)
        sessions.append(session)
        activeSessionId = session.id
        saveSessions()
        return session
    }

    func closeSession(id: UUID) {
        TerminalService.shared.terminateProcess(for: id)
        sessions.removeAll { $0.id == id }
        if activeSessionId == id {
            activeSessionId = sessions.last?.id
        }
        saveSessions()
    }

    func switchToSession(id: UUID) {
        guard sessions.contains(where: { $0.id == id }) else { return }
        activeSessionId = id
    }

    func renameSession(id: UUID, to newName: String) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].name = newName
        saveSessions()
    }

    // MARK: - Persistence

    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey),
              let decoded = try? JSONDecoder().decode([Session].self, from: data)
        else { return }
        sessions = decoded
    }

    private func saveSessions() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: sessionsKey)
    }

    // MARK: - VS Code Workspace Config

    struct VSCodeWorkspaceConfig: Codable {
        let filePath: String
        let primaryDir: String
        let relatedDirs: [String]
        var needsRestart: Bool = false
    }

    /// Try to mount a .code-workspace file to the matching workspace.
    /// Returns success/error message.
    @discardableResult
    func mountVSCodeWorkspace(_ workspaceFilePath: String) -> MountResult {
        guard let data = FileManager.default.contents(atPath: workspaceFilePath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let folders = json["folders"] as? [[String: Any]],
              !folders.isEmpty
        else {
            return .error(Localization.shared.current == .chinese
                ? "无法解析 .code-workspace 文件"
                : "Failed to parse .code-workspace file")
        }

        // Get the first folder as primary directory
        guard let firstFolder = folders.first,
              let relativePath = firstFolder["path"] as? String
        else {
            return .error(Localization.shared.current == .chinese
                ? "工作区配置中没有找到目录"
                : "No directories found in workspace config")
        }

        // Resolve relative path against the .code-workspace file location
        let workspaceDir = URL(fileURLWithPath: workspaceFilePath).deletingLastPathComponent().path
        let primaryDir = ((workspaceDir as NSString).appendingPathComponent(relativePath) as NSString).standardizingPath

        // Check if there's a workspace with this primary directory
        let hasMatchingWorkspace = sessions.contains { $0.workingDirectory == primaryDir }
        guard hasMatchingWorkspace else {
            let dirName = URL(fileURLWithPath: primaryDir).lastPathComponent
            return .noMatchingWorkspace(dirName)
        }

        // Extract related dirs (folders after the first)
        var related: [String] = []
        for folder in folders.dropFirst() {
            if let path = folder["path"] as? String {
                let resolved = ((workspaceDir as NSString).appendingPathComponent(path) as NSString).standardizingPath
                related.append(resolved)
            }
        }

        // Save config
        let config = VSCodeWorkspaceConfig(
            filePath: workspaceFilePath,
            primaryDir: primaryDir,
            relatedDirs: related,
            needsRestart: workspaceConfigs[primaryDir]?.filePath != workspaceFilePath
        )
        workspaceConfigs[primaryDir] = config
        saveWorkspaceConfigs()

        return .success
    }

    /// Unmount the VS Code workspace config from a workspace.
    func unmountVSCodeWorkspace(workspacePath: String) {
        workspaceConfigs.removeValue(forKey: workspacePath)
        saveWorkspaceConfigs()
    }

    /// Mark a workspace as having no pending restart (called after new session is created).
    func clearNeedsRestart(workspacePath: String) {
        workspaceConfigs[workspacePath]?.needsRestart = false
        saveWorkspaceConfigs()
    }

    /// Get the --add-dir arguments for a workspace's working directory.
    func addDirArguments(for workingDirectory: String) -> [String] {
        guard let config = workspaceConfigs[workingDirectory],
              !config.relatedDirs.isEmpty else {
            return []
        }
        return config.relatedDirs.flatMap { ["--add-dir", $0] }
    }

    // MARK: - Workspace Config Persistence

    private func loadWorkspaceConfigs() {
        guard let data = UserDefaults.standard.data(forKey: workspaceConfigsKey),
              let decoded = try? JSONDecoder().decode([String: VSCodeWorkspaceConfig].self, from: data)
        else { return }
        workspaceConfigs = decoded
    }

    private func saveWorkspaceConfigs() {
        guard let data = try? JSONEncoder().encode(workspaceConfigs) else { return }
        UserDefaults.standard.set(data, forKey: workspaceConfigsKey)
    }

    enum MountResult {
        case success
        case noMatchingWorkspace(String)  // the directory name that's missing
        case error(String)
    }
}
