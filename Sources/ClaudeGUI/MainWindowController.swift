import AppKit
import SwiftUI
import SwiftTerm

/// A single agent session from `claude agents --json`.
struct AgentSession: Codable, Identifiable {
    let pid: Int
    let cwd: String
    let kind: String
    let startedAt: Int64
    let sessionId: String
    let name: String?
    let status: String?

    var id: String { sessionId }
    var displayName: String { name ?? String(sessionId.prefix(8)) }
    var displayStatus: String { status ?? kind }
}

/// Bridge object to hold callbacks for SwiftUI sidebar
class SidebarCallback: ObservableObject {
    var onSelect: ((UUID) -> Void)?
    var onClose: ((UUID) -> Void)?
    var onStop: ((UUID) -> Void)?
    var onOverview: (() -> Void)?
    var onNewSession: (() -> Void)?
}

class MainWindowController: NSWindowController, NSSplitViewDelegate {

    // Layout
    private let splitView = NSSplitView()
    private var sidebarHostingView: NSView!
    private let terminalContainer = NSView()

    // Overview terminal (runs `claude agents`)
    private var overviewTerminal: DragDropTerminalView?

    // Session terminals (runs `claude attach <sessionId>`)
    private var sessionTerminals: [String: DragDropTerminalView] = [:]
    private var activeTerminal: DragDropTerminalView?

    // Agent sessions from `claude agents --json`
    private var agentSessions: [AgentSession] = []
    private var activeSessionIndex: Int?

    // SessionManager for SwiftUI sidebar
    private let sessionManager = SessionManager()
    private let sidebarCallback = SidebarCallback()

    // Polling timer
    private var pollTimer: Timer?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Claude GUI"
        window.center()
        window.minSize = NSSize(width: 700, height: 400)

        self.init(window: window)
        setupUI()
        setupSidebarCallbacks()
        launchOverviewTerminal()
        startPolling()
    }

    deinit {
        pollTimer?.invalidate()
    }

    // MARK: - UI Setup

    private func setupUI() {
        guard let window = window else { return }

        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.delegate = self
        splitView.frame = window.contentView!.bounds
        splitView.autoresizingMask = [.width, .height]

        // Create SwiftUI sidebar
        let sidebarView = SidebarSessionView(sessionManager: sessionManager, callback: sidebarCallback)
        sidebarHostingView = NSHostingView(rootView: sidebarView)
        sidebarHostingView.frame = NSRect(x: 0, y: 0, width: 220, height: 700)
        splitView.addSubview(sidebarHostingView)

        // Terminal container
        terminalContainer.wantsLayer = true
        terminalContainer.layer?.backgroundColor = AppTheme.termContainerBg.cgColor
        splitView.addSubview(terminalContainer)

        splitView.setPosition(220, ofDividerAt: 0)
        window.contentView = splitView

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            return self?.handleKeyDown(event) ?? event
        }
    }

    private func setupSidebarCallbacks() {
        sidebarCallback.onSelect = { [weak self] sessionId in
            self?.enterAgentSession(sessionId: sessionId)
        }
        sidebarCallback.onClose = { [weak self] sessionId in
            self?.closeAgentSession(sessionId: sessionId)
        }
        sidebarCallback.onStop = { [weak self] sessionId in
            self?.stopAgentSession(sessionId: sessionId)
        }
        sidebarCallback.onOverview = { [weak self] in
            self?.showOverviewTerminal()
        }
        sidebarCallback.onNewSession = { [weak self] in
            self?.launchNewSession()
        }
    }

    // MARK: - Terminal Management

    private func makeTerminal() -> DragDropTerminalView {
        let tv = DragDropTerminalView(frame: terminalContainer.bounds)
        tv.autoresizingMask = [.width, .height]
        tv.configureNativeColors()
        tv.terminal.backgroundColor = AppTheme.termBg
        tv.terminal.foregroundColor = AppTheme.termFg
        return tv
    }

    private func launchOverviewTerminal() {
        let tv = makeTerminal()
        let claudePath = getClaudePath()
        tv.startProcess(
            executable: "/bin/zsh",
            args: ["-l", "-c", "\(claudePath) agents"],
            environment: nil,
            currentDirectory: FileManager.default.homeDirectoryForCurrentUser.path
        )
        terminalContainer.addSubview(tv)
        overviewTerminal = tv
        activeTerminal = tv
        window?.makeFirstResponder(tv)
    }

    private func showTerminal(_ tv: DragDropTerminalView) {
        guard tv !== activeTerminal else { return }
        activeTerminal?.isHidden = true
        tv.frame = terminalContainer.bounds
        tv.isHidden = false
        terminalContainer.addSubview(tv)
        activeTerminal = tv
        window?.makeFirstResponder(tv)
    }

    private func showOverviewTerminal() {
        guard let tv = overviewTerminal else { return }
        activeSessionIndex = nil
        syncSessionManagerFromAgents()
        showTerminal(tv)
    }

    private func openSessionTerminal(sessionId: String) {
        if let existing = sessionTerminals[sessionId] {
            showTerminal(existing)
            return
        }

        let shortId = sessionId.components(separatedBy: "-").first ?? sessionId
        let tv = makeTerminal()
        let claudePath = getClaudePath()
        tv.startProcess(
            executable: "/bin/zsh",
            args: ["-l", "-c", "\(claudePath) attach \(shortId)"],
            environment: nil,
            currentDirectory: FileManager.default.homeDirectoryForCurrentUser.path
        )
        terminalContainer.addSubview(tv)
        sessionTerminals[sessionId] = tv
        showTerminal(tv)
    }

    // MARK: - Themed TextField

    private struct ThemedTextField: NSViewRepresentable {
        let placeholder: String
        @Binding var text: String
        let font: NSFont
        let textColor: NSColor
        let placeholderColor: NSColor
        let onSubmit: () -> Void

        func makeNSView(context: Context) -> NSTextField {
            let field = NSTextField()
            field.isBordered = false
            field.isBezeled = false
            field.drawsBackground = false
            field.font = font
            field.textColor = textColor
            field.placeholderAttributedString = NSAttributedString(
                string: placeholder,
                attributes: [
                    .font: font,
                    .foregroundColor: placeholderColor
                ]
            )
            field.focusRingType = .none
            field.delegate = context.coordinator
            field.lineBreakMode = .byTruncatingTail
            field.cell?.wraps = false
            field.cell?.isScrollable = true
            return field
        }

        func updateNSView(_ field: NSTextField, context: Context) {
            if field.stringValue != text {
                field.stringValue = text
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, NSTextFieldDelegate {
            var parent: ThemedTextField

            init(_ parent: ThemedTextField) {
                self.parent = parent
            }

            func controlTextDidChange(_ obj: Notification) {
                if let field = obj.object as? NSTextField {
                    parent.text = field.stringValue
                }
            }

            func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
                if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                    parent.onSubmit()
                    return true
                }
                return false
            }
        }
    }

    // MARK: - New Session Dialog

    private var newSessionDialogWindow: NSWindow?

    private struct NewSessionDialogContent: View {
        @Binding var taskText: String
        @Binding var directoryURL: URL
        @ObservedObject var localization = Localization.shared
        let onSubmit: () -> Void
        let onCancel: () -> Void
        let onBrowse: () -> Void

        private let surface = AppTheme.bgSurface
        private let surfaceAlt = AppTheme.bgElevated
        private let border = AppTheme.borderDefault
        private let textPrimary = AppTheme.textPrimary
        private let textSecondary = AppTheme.textSecondary

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.accentColor)
                    Text(L10n.newSession)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(textPrimary)
                }
                .padding(.bottom, 20)

                // Task input
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.newSessionPrompt)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(textSecondary)

                    ThemedTextField(
                        placeholder: L10n.newSessionPlaceholder,
                        text: $taskText,
                        font: .systemFont(ofSize: 13),
                        textColor: NSColor(textPrimary),
                        placeholderColor: NSColor(AppTheme.textMuted),
                        onSubmit: { onSubmit() }
                    )
                    .frame(height: 20)
                    .padding(10)
                        .background(surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.lg)
                                .stroke(border, lineWidth: 1)
                        )
                        .onSubmit { onSubmit() }
                }
                .padding(.bottom, 16)

                // Directory picker
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.workingDirectory)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(textSecondary)

                    Button(action: { onBrowse() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.accentColor.opacity(0.7))

                            Text(directoryURL.path)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(textPrimary.opacity(0.8))
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            Text(L10n.browse)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding(10)
                        .background(surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.lg)
                                .stroke(border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 24)

                // Buttons
                HStack(spacing: 10) {
                    Spacer()

                    Button(action: { onCancel() }) {
                        Text(L10n.cancel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(textSecondary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)
                    .background(surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(border, lineWidth: 1)
                    )

                    Button(action: { onSubmit() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                            Text(L10n.createSession)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .disabled(taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                }
            }
            .padding(24)
            .frame(width: 440)
            .background(AppTheme.bgBase)
        }
    }

    private class NewSessionDialogWindow: NSWindow {
        override var canBecomeKey: Bool { true }
    }

    private class NewSessionState: ObservableObject {
        @Published var taskText = ""
        @Published var directoryURL = FileManager.default.homeDirectoryForCurrentUser
    }

    private func launchNewSession() {
        let state = NewSessionState()

        func submit() {
            let task = state.taskText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !task.isEmpty else { return }
            newSessionDialogWindow?.close()
            newSessionDialogWindow = nil

            let tv = makeTerminal()
            let claudePath = getClaudePath()
            let escaped = task.replacingOccurrences(of: "\"", with: "\\\"")
            tv.startProcess(
                executable: "/bin/zsh",
                args: ["-l", "-c", "\(claudePath) --bg \"\(escaped)\""],
                environment: nil,
                currentDirectory: state.directoryURL.path
            )
            terminalContainer.addSubview(tv)
            showTerminal(tv)
        }

        func cancel() {
            newSessionDialogWindow?.close()
            newSessionDialogWindow = nil
        }

        func browse() {
            newSessionDialogWindow?.close()
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.canCreateDirectories = true
            panel.directoryURL = state.directoryURL
            if panel.runModal() == .OK, let url = panel.url {
                state.directoryURL = url
            }
            presentNewSessionDialog(state: state, onSubmit: submit, onCancel: cancel, onBrowse: browse)
        }

        presentNewSessionDialog(state: state, onSubmit: submit, onCancel: cancel, onBrowse: browse)
    }

    private func presentNewSessionDialog(
        state: NewSessionState,
        onSubmit: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onBrowse: @escaping () -> Void
    ) {
        let content = NewSessionDialogContent(
            taskText: Binding(get: { state.taskText }, set: { state.taskText = $0 }),
            directoryURL: Binding(get: { state.directoryURL }, set: { state.directoryURL = $0 }),
            onSubmit: onSubmit,
            onCancel: onCancel,
            onBrowse: onBrowse
        )

        let hostingView = NSHostingView(rootView: content)
        hostingView.frame.size = hostingView.fittingSize

        let dialogWindow = NewSessionDialogWindow(
            contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        dialogWindow.titlebarAppearsTransparent = true
        dialogWindow.isMovableByWindowBackground = true
        dialogWindow.contentView = hostingView
        dialogWindow.isReleasedWhenClosed = false

        if let parentWindow = window {
            parentWindow.beginSheet(dialogWindow) { _ in
                self.newSessionDialogWindow = nil
            }
        }

        newSessionDialogWindow = dialogWindow
    }

    // MARK: - Polling

    private func startPolling() {
        pollAgentSessions()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.pollAgentSessions()
        }
    }

    private func pollAgentSessions() {
        let claudePath = getClaudePath()
        let cmd = "\(claudePath) agents --json"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", cmd]

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
        } catch {
            NSLog("ClaudeGUI: poll run error: %@", error.localizedDescription)
            return
        }

        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        if process.terminationStatus != 0 || data.isEmpty {
            let stderr = String(data: errData, encoding: .utf8) ?? ""
            NSLog("ClaudeGUI: poll failed, status=%d, err=%@", process.terminationStatus, stderr)
            return
        }

        do {
            let agents = try JSONDecoder().decode([AgentSession].self, from: data)
            DispatchQueue.main.async { [weak self] in
                self?.agentSessions = agents
                self?.syncSessionManagerFromAgents()
            }
        } catch {
            NSLog("ClaudeGUI: poll decode error: %@", error.localizedDescription)
        }
    }

    private func syncSessionManagerFromAgents() {
        let backgroundAgents = agentSessions.filter { $0.kind == "background" }
        let newSessions: [Session] = backgroundAgents.map { agent in
            let shortId = agent.sessionId.components(separatedBy: "-").first ?? String(agent.sessionId.prefix(8))
            return Session(
                id: UUID(uuidString: agent.sessionId) ?? UUID(),
                name: agent.name ?? shortId,
                shortId: shortId,
                workingDirectory: agent.cwd,
                createdAt: Date(timeIntervalSince1970: TimeInterval(agent.startedAt) / 1000),
                status: agent.status ?? "idle"
            )
        }
        sessionManager.sessions = newSessions
        sessionManager.activeSessionId = activeSessionIndex.flatMap { idx in
            idx < backgroundAgents.count ? UUID(uuidString: backgroundAgents[idx].sessionId) : nil
        }
    }

    // MARK: - Session Actions

    private func enterAgentSession(sessionId: UUID) {
        let idString = sessionId.uuidString.lowercased()
        let backgroundAgents = agentSessions.filter { $0.kind == "background" }
        guard let bgIndex = backgroundAgents.firstIndex(where: { $0.sessionId.lowercased() == idString }) else {
            NSLog("ClaudeGUI: enterAgentSession — session not found: %@", idString)
            return
        }
        activeSessionIndex = bgIndex
        syncSessionManagerFromAgents()
        openSessionTerminal(sessionId: idString)
    }

    private func closeAgentSession(sessionId: UUID) {
        let idString = sessionId.uuidString.lowercased()
        let shortId = idString.components(separatedBy: "-").first ?? idString
        runClaudeCommand("rm", shortId: shortId)
        if let tv = sessionTerminals.removeValue(forKey: idString) {
            tv.isHidden = true
            tv.removeFromSuperview()
        }
        if activeSessionIndex != nil {
            showOverviewTerminal()
        }
    }

    private func stopAgentSession(sessionId: UUID) {
        let idString = sessionId.uuidString.lowercased()
        let shortId = idString.components(separatedBy: "-").first ?? idString
        runClaudeCommand("stop", shortId: shortId)
        if let tv = sessionTerminals.removeValue(forKey: idString) {
            tv.isHidden = true
            tv.removeFromSuperview()
        }
        if activeSessionIndex != nil {
            showOverviewTerminal()
        }
    }

    private func runClaudeCommand(_ command: String, shortId: String) {
        let claudePath = getClaudePath()
        let cmd = "\(claudePath) \(command) \(shortId)"
        DispatchQueue.global(qos: .background).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-l", "-c", cmd]
            try? process.run()
            process.waitUntilExit()
        }
    }

    // MARK: - Keyboard

    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        guard let window = window, window.isKeyWindow else { return event }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains(.command) else { return event }

        if event.charactersIgnoringModifiers == "r" {
            pollAgentSessions()
            return nil
        }

        let backgroundAgents = agentSessions.filter { $0.kind == "background" }
        if let char = event.charactersIgnoringModifiers, let num = Int(char), num >= 1 && num <= 9 && num <= backgroundAgents.count {
            let agent = backgroundAgents[num - 1]
            if let uuid = UUID(uuidString: agent.sessionId) {
                enterAgentSession(sessionId: uuid)
            }
            return nil
        }

        return event
    }

    // MARK: - NSSplitViewDelegate

    func splitView(_ splitView: NSSplitView, shouldAdjustSubviewProposedPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return max(180, min(300, proposedPosition))
    }

    // MARK: - Helpers

    private func getClaudePath() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let versionsDir = "\(home)/.nvm/versions/node"
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: versionsDir) {
            let sorted = contents.sorted(by: >)
            for version in sorted {
                let path = "\(versionsDir)/\(version)/bin/claude"
                if FileManager.default.isExecutableFile(atPath: path) {
                    return path
                }
            }
        }
        return "claude"
    }
}
