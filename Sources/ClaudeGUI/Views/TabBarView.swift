import SwiftUI

struct SidebarSessionView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var callback: SidebarCallback
    @ObservedObject var localization = Localization.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var envChecker = EnvironmentChecker.shared
    @State private var showEnvPopover = false
    @State private var toastMessage: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n.agents)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                // Mount VS Code workspace
                Button(action: {
                    callback.onMountWorkspace?("")
                }) {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textMuted)
                }
                .buttonStyle(.plain)
                .help(localization.current == .chinese ? "挂载 VS Code 工作区配置，关联 .vscode 目录到当前项目" : "Mount VS Code workspace — link a .vscode folder to the current project")
                // Environment status
                Button(action: { showEnvPopover.toggle() }) {
                    Circle()
                        .fill(envColor)
                        .frame(width: 8, height: 8)
                }
                .buttonStyle(.plain)
                .help(localization.current == .chinese ? "环境检测状态：绿色 = 正常，红色 = 异常" : "Environment status: green = OK, red = error")
                .popover(isPresented: $showEnvPopover) {
                    envPopoverContent
                }
                // Theme toggle
                Button(action: { themeManager.next() }) {
                    Text(themeName(themeManager.current))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.accentBg)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                }
                .buttonStyle(.plain)
                // Language toggle
                Button(action: { localization.toggle() }) {
                    Text(localization.current == .chinese ? "EN" : "中")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.accentBg)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                }
                .buttonStyle(.plain)
                .help(localization.current == .chinese ? "切换界面语言" : "Toggle interface language")
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, 10)

            Divider()
                .overlay(AppTheme.divider)

            ScrollView {
                VStack(spacing: 0) {
                    allSessionsButton

                    newSessionButton

                    Divider()
                        .overlay(AppTheme.divider)
                        .padding(.vertical, 6)

                    let workspaces = sessionManager.workspaces
                    if workspaces.isEmpty {
                        Text(L10n.noWorkspaces)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textMuted)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(workspaces) { workspace in
                            workspaceSection(workspace: workspace)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }

            Divider()
                .overlay(AppTheme.divider)

            HStack {
                let ws = sessionManager.workspaces
                Text("\(ws.count) \(L10n.workspaces.lowercased()) · \(L10n.agentCount(sessionManager.sessions.count))")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textMuted)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, 4)

            // Permission mode cycle button
            Button(action: { callback.onCyclePermissionMode?() }) {
                HStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textMuted)
                    Text(L10n.permissionMode)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.accentColor.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, 6)

            Divider()
                .overlay(AppTheme.divider)

            HStack {
                Text("v1.0.0")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textMuted.opacity(0.6))
                Spacer()
                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://github.com/xuxuxuzw/ClaudeGUI")!)
                }) {
                    Image(systemName: "arrow.up.forward.square")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textMuted.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help("GitHub: xuxuxuzw/ClaudeGUI")
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, 4)
        }
        .overlay(alignment: .center) {
            if let msg = toastMessage {
                Text(msg)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.75)))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toastMessage)
        .background(AppTheme.bgBase)
    }

    private func themeName(_ scheme: ColorScheme) -> String {
        let isCN = localization.current == .chinese
        switch scheme {
        case .basic:      return isCN ? "基础" : "Basic"
        case .clearDark:  return isCN ? "暗色" : "Dark"
        case .clearLight: return isCN ? "亮色" : "Light"
        }
    }

    // MARK: - Environment Status

    private var envColor: Color {
        if envChecker.isChecking { return .gray }
        if envChecker.hasFail { return .red }
        if envChecker.allOk { return .green }
        return .gray
    }

    private var envPopoverContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.envCheck)
                .font(.system(size: 13, weight: .semibold))
                .padding(.bottom, 4)

            envRow(label: L10n.nodeJs, status: envChecker.nodeStatus)
            envRow(label: L10n.claudeCli, status: envChecker.cliStatus)
            envRow(label: L10n.loginStatus, status: envChecker.loginStatus)

            Divider()

            Button(action: { envChecker.check() }) {
                Text(L10n.checking)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(envChecker.isChecking)
        }
        .padding(12)
        .frame(width: 180)
    }

    private func envRow(label: String, status: CheckStatus) -> some View {
        HStack {
            Circle()
                .fill(status == .ok ? .green : status == .fail ? .red : .gray)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Text(status == .ok ? L10n.envOk : status == .fail ? L10n.envFail : L10n.checking)
                .font(.system(size: 11))
                .foregroundStyle(status == .ok ? .green : status == .fail ? .red : AppTheme.textMuted)
        }
    }

    // MARK: - All Sessions Button

    private var allSessionsButton: some View {
        Button(action: {
            sessionManager.activeSessionId = nil
            callback.onOverview?()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 14))
                    .frame(width: 20)
                    .foregroundStyle(Color.accentColor)
                Text(L10n.allSessions)
                    .font(.system(size: 14, weight: sessionManager.activeSessionId == nil ? .semibold : .regular))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                if sessionManager.activeSessionId == nil {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: 3, height: 16)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(sessionManager.activeSessionId == nil ? AppTheme.accentBg : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - New Session Button

    private var newSessionButton: some View {
        Button(action: {
            callback.onNewSession?()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                    .frame(width: 20)
                    .foregroundStyle(Color.accentColor.opacity(0.8))
                Text(L10n.newSession)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Session Group

    @State private var expandedGroups: Set<String> = ["awaiting", "working", "completed", "idle"]
    @State private var expandedWorkspaces: Set<String> = []
    @State private var expandedRelatedDirs: Set<String> = []

    // MARK: - Workspace Section

    @ViewBuilder
    private func workspaceSection(workspace: Workspace) -> some View {
        let isExpanded = expandedWorkspaces.contains(workspace.path)
        let totalSessions = workspace.sessions.count

        VStack(spacing: 0) {
            // Workspace header
            Button(action: {
                sessionManager.activeWorkspacePath = workspace.path
                if isExpanded {
                    expandedWorkspaces.remove(workspace.path)
                } else {
                    expandedWorkspaces.insert(workspace.path)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: workspace.vscodeWorkspacePath != nil ? "folder.fill.badge.gearshape" : "folder.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.accentColor.opacity(0.7))
                    Text(workspace.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text("\(totalSessions)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(AppTheme.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                // Full path hint
                HStack(spacing: 4) {
                    Text(workspace.path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(AppTheme.textMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 4)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(workspace.path, forType: .string)
                    toastMessage = localization.current == .chinese ? "已复制!" : "Copied!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toastMessage = nil }
                }
                .help(localization.current == .chinese ? "双击复制路径" : "Double-click to copy path")

                // Needs restart indicator
                if workspace.needsRestart {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text(localization.current == .chinese ? "工作区配置已变更，请新建会话" : "Config changed, create a new session")
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                        Spacer()
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 4)
                }

                // Unmount workspace button
                if workspace.vscodeWorkspacePath != nil {
                    HStack {
                        Button(action: {
                            callback.onUnmountWorkspace?(workspace.path)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11))
                                Text(localization.current == .chinese ? "取消挂载工作区" : "Unmount workspace")
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(.orange)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 4)
                }

                // Related dirs display
                if !workspace.relatedDirs.isEmpty {
                    let dirKey = "\(workspace.path)/relatedDirs"
                    let isRelatedDirsExpanded = expandedRelatedDirs.contains(dirKey)

                    VStack(alignment: .leading, spacing: 2) {
                        Button(action: {
                            if isRelatedDirsExpanded {
                                expandedRelatedDirs.remove(dirKey)
                            } else {
                                expandedRelatedDirs.insert(dirKey)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(localization.current == .chinese ? "关联目录" : "Related dirs")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(AppTheme.textMuted)
                                Text("(\(workspace.relatedDirs.count))")
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppTheme.textMuted.opacity(0.6))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(AppTheme.textMuted)
                                    .rotationEffect(.degrees(isRelatedDirsExpanded ? 90 : 0))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if isRelatedDirsExpanded {
                            ForEach(workspace.relatedDirs, id: \.self) { dir in
                                HStack(spacing: 4) {
                                    Image(systemName: "folder")
                                        .font(.system(size: 9))
                                        .foregroundStyle(AppTheme.textMuted)
                                    Text(URL(fileURLWithPath: dir).lastPathComponent)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(AppTheme.textMuted)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(dir, forType: .string)
                                    toastMessage = localization.current == .chinese ? "已复制!" : "Copied!"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toastMessage = nil }
                                }
                                .help(localization.current == .chinese ? "双击复制路径" : "Double-click to copy path")
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 4)
                }

                // Status groups within this workspace
                let ws = workspace.sessions
                sessionGroup(
                    title: L10n.awaitingInput,
                    icon: "clock",
                    color: .green,
                    groupKey: "\(workspace.path)/awaiting",
                    sessions: ws.filter { $0.status == "waiting" }
                )
                sessionGroup(
                    title: L10n.working,
                    icon: "gear",
                    color: .orange,
                    groupKey: "\(workspace.path)/working",
                    sessions: ws.filter { $0.status == "working" }
                )
                sessionGroup(
                    title: L10n.completed,
                    icon: "checkmark.circle",
                    color: .blue,
                    groupKey: "\(workspace.path)/completed",
                    sessions: ws.filter { $0.status == "completed" }
                )
                sessionGroup(
                    title: L10n.idle,
                    icon: "moon",
                    color: .gray,
                    groupKey: "\(workspace.path)/idle",
                    sessions: ws.filter { $0.status != "waiting" && $0.status != "working" && $0.status != "completed" }
                )
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Session Group

    @ViewBuilder
    private func sessionGroup(title: String, icon: String, color: Color, groupKey: String, sessions: [Session]) -> some View {
        let isExpanded = expandedGroups.contains(groupKey)

        VStack(spacing: 0) {
            Button(action: {
                if isExpanded {
                    expandedGroups.remove(groupKey)
                } else {
                    expandedGroups.insert(groupKey)
                }
            }) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("\(sessions.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                if sessions.isEmpty {
                    Text(L10n.noSessions)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textMuted)
                        .padding(.leading, 20)
                        .padding(.vertical, 4)
                } else {
                    ForEach(sessions) { session in
                        sessionRow(session: session, color: color)
                            .padding(.leading, 4)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Session Row

    private func sessionRow(session: Session, color: Color) -> some View {
        let isActive = sessionManager.activeSessionId == session.id

        return Button(action: {
            sessionManager.switchToSession(id: session.id)
            callback.onSelect?(session.id)
        }) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)

                Text(session.shortId)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.textMuted)

                Text(session.name)
                    .font(.system(size: 14, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .lineLimit(1)

                Spacer()

                if isActive {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: 3, height: 16)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isActive ? AppTheme.accentBg : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: {
                callback.onStop?(session.id)
            }) {
                Label(L10n.stopSession, systemImage: "stop.circle")
            }

            Button(role: .destructive, action: {
                callback.onClose?(session.id)
            }) {
                Label(L10n.deleteSession, systemImage: "trash")
            }
        }
    }
}
