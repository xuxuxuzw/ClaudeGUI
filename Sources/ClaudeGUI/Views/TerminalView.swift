import SwiftUI
import SwiftTerm

/// Wraps SwiftTerm's LocalProcessTerminalView for use in SwiftUI.
/// Each instance runs an independent `claude` CLI session via PTY.
struct TerminalViewRepresentable: NSViewRepresentable {
    let sessionId: UUID
    let workingDirectory: String
    let isActive: Bool

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let tv = LocalProcessTerminalView(frame: .zero)

        // Dark terminal theme
        tv.configureNativeColors()
        tv.terminal.backgroundColor = AppTheme.termBg
        tv.terminal.foregroundColor = AppTheme.termFg

        // Register for lifecycle management
        TerminalService.shared.register(terminalView: tv, for: sessionId)

        // Launch claude inside the PTY
        let shell = TerminalService.shared.getShell()
        let claudePath = TerminalService.shared.getClaudePath()
        let nodeBinDir = (claudePath as NSString).deletingLastPathComponent
        let pathEnv = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/local/bin:/usr/bin:/bin"
        let fullPath = "\(nodeBinDir):\(pathEnv)"
        tv.startProcess(
            executable: shell,
            args: ["-c", "export PATH=\"\(fullPath)\" && \(claudePath)"],
            environment: nil,
            currentDirectory: workingDirectory
        )

        DispatchQueue.main.async {
            _ = tv.becomeFirstResponder()
        }

        return tv
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        nsView.isHidden = !isActive
    }

    static func dismantleNSView(_ nsView: LocalProcessTerminalView, coordinator: ()) {
        nsView.terminate()
    }
}

extension TerminalViewRepresentable: Equatable {
    static func == (lhs: TerminalViewRepresentable, rhs: TerminalViewRepresentable) -> Bool {
        return lhs.sessionId == rhs.sessionId
            && lhs.workingDirectory == rhs.workingDirectory
            && lhs.isActive == rhs.isActive
    }
}
