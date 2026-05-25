import SwiftUI
import SwiftTerm
import AppKit

class TerminalHostingView: NSView {
    let terminalView: LocalProcessTerminalView

    init(terminalView: LocalProcessTerminalView) {
        self.terminalView = terminalView
        super.init(frame: .zero)
        addSubview(terminalView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        if terminalView.frame != bounds {
            terminalView.frame = bounds
        }
    }

    override var isFlipped: Bool {
        return true
    }
}

struct TerminalViewRepresentable: NSViewRepresentable {
    let sessionId: UUID
    let workingDirectory: String
    let isActive: Bool

    func makeNSView(context: Context) -> TerminalHostingView {
        let tv = LocalProcessTerminalView(frame: .zero)

        tv.configureNativeColors()
        tv.terminal.backgroundColor = AppTheme.termBg
        tv.terminal.foregroundColor = AppTheme.termFg

        let host = TerminalHostingView(terminalView: tv)

        TerminalService.shared.register(terminalView: tv, for: sessionId)

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

        return host
    }

    func updateNSView(_ hostView: TerminalHostingView, context: Context) {
        hostView.terminalView.isHidden = !isActive
        hostView.needsLayout = true
    }

    static func dismantleNSView(_ hostView: TerminalHostingView, coordinator: ()) {
        hostView.terminalView.terminate()
    }
}

extension TerminalViewRepresentable: Equatable {
    static func == (lhs: TerminalViewRepresentable, rhs: TerminalViewRepresentable) -> Bool {
        return lhs.sessionId == rhs.sessionId
            && lhs.workingDirectory == rhs.workingDirectory
            && lhs.isActive == rhs.isActive
    }
}
